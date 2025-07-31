// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./DappToken.sol";
import "./LPToken.sol";

/**
* @title Proportional Token Farm
* @notice Una granja de staking donde las recompensas se distribuyen proporcionalmente al total stakeado.
*/
contract TokenFarm {
    //
    // Variables de estado
    //
    string public name = "Proportional Token Farm";
    address public owner;
    DAppToken public dappToken;
    LPToken public lpToken;
    
    uint256 public constant REWARD_PER_BLOCK = 1e18; // Recompensa por bloque (total para todos los usuarios)
    uint256 public totalStakingBalance; // Total de tokens en staking
    address[] public stakers;
    
    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public checkpoints;
    mapping(address => uint256) public pendingRewards;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    // Eventos
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsDistributed();

    // Constructor
    constructor(DAppToken _dappToken, LPToken _lpToken) {
        // Configurar las instancias de los contratos de DappToken y LPToken.
        dappToken = _dappToken;
        lpToken = _lpToken;
        // Configurar al owner del contrato como el creador de este contrato.
        owner = msg.sender;
    }

    /**
    * @notice Deposita tokens LP para staking.
    * @param _amount Cantidad de tokens LP a depositar.
    */
    function deposit(uint256 _amount) external {
        // Verificar que _amount sea mayor a 0.
        require(_amount > 0, "Amount must be greater than 0");
        
        // Transferir tokens LP del usuario a este contrato.
        lpToken.transferFrom(msg.sender, address(this), _amount);
        
        // Actualizar el balance de staking del usuario en stakingBalance.
        stakingBalance[msg.sender] += _amount;
        
        // Incrementar totalStakingBalance con _amount.
        totalStakingBalance += _amount;
        
        // Si el usuario nunca ha hecho staking antes, agregarlo al array stakers y marcar hasStaked como true.
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
            hasStaked[msg.sender] = true;
        }
        
        // Actualizar isStaking del usuario a true.
        isStaking[msg.sender] = true;
        
        // Si checkpoints del usuario está vacío, inicializarlo con el número de bloque actual.
        if (checkpoints[msg.sender] == 0) {
            checkpoints[msg.sender] = block.number;
        }
        
        // Llamar a distributeRewards para calcular y actualizar las recompensas pendientes.
        distributeRewards(msg.sender);
        
        // Emitir un evento de depósito.
        emit Deposit(msg.sender, _amount);
    }

    /**
    * @notice Retira todos los tokens LP en staking.
    */
    function withdraw() external {
        // Verificar que el usuario está haciendo staking (isStaking == true).
        require(isStaking[msg.sender], "User is not staking");
        
        // Obtener el balance de staking del usuario.
        uint256 balance = stakingBalance[msg.sender];
        
        // Verificar que el balance de staking sea mayor a 0.
        require(balance > 0, "Staking balance is 0");
        
        // Llamar a distributeRewards para calcular y actualizar las recompensas pendientes antes de restablecer el balance.
        distributeRewards(msg.sender);
        
        // Restablecer stakingBalance del usuario a 0.
        stakingBalance[msg.sender] = 0;
        
        // Reducir totalStakingBalance en el balance que se está retirando.
        totalStakingBalance -= balance;
        
        // Actualizar isStaking del usuario a false.
        isStaking[msg.sender] = false;
        
        // Transferir los tokens LP de vuelta al usuario.
        lpToken.transfer(msg.sender, balance);
        
        // Emitir un evento de retiro.
        emit Withdraw(msg.sender, balance);
    }

    /**
    * @notice Reclama recompensas pendientes.
    */
    function claimRewards() external {
        // Obtener el monto de recompensas pendientes del usuario desde pendingRewards.
        uint256 pendingAmount = pendingRewards[msg.sender];
        
        // Verificar que el monto de recompensas pendientes sea mayor a 0.
        require(pendingAmount > 0, "No pending rewards");
        
        // Restablecer las recompensas pendientes del usuario a 0.
        pendingRewards[msg.sender] = 0;
        
        // Llamar a la función de acuñación (mint) en el contrato DappToken para transferir las recompensas al usuario.
        dappToken.mint(msg.sender, pendingAmount);
        
        // Emitir un evento de reclamo de recompensas.
        emit RewardsClaimed(msg.sender, pendingAmount);
    }

    /**
    * @notice Distribuye recompensas a todos los usuarios en staking.
    */
    function distributeRewardsAll() external {
        // Verificar que la llamada sea realizada por el owner.
        require(msg.sender == owner, "Only owner can call this function");
        
        // Iterar sobre todos los usuarios en staking almacenados en el array stakers.
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            // Para cada usuario, si están haciendo staking (isStaking == true), llamar a distributeRewards.
            if (isStaking[staker]) {
                distributeRewards(staker);
            }
        }
        
        // Emitir un evento indicando que las recompensas han sido distribuidas.
        emit RewardsDistributed();
    }

    function distributeRewards(address beneficiary) private {
        // Obtener el último checkpoint del usuario desde checkpoints.
        uint256 lastCheckpoint = checkpoints[beneficiary];
        
        // Verificar que el número de bloque actual sea mayor al checkpoint y que totalStakingBalance sea mayor a 0.
        if (block.number <= lastCheckpoint || totalStakingBalance == 0) {
            return;
        }
        
        // Calcular la cantidad de bloques transcurridos desde el último checkpoint.
        uint256 blocksPassed = block.number - lastCheckpoint;
        
        // Calcular la proporción del staking del usuario en relación al total staking (stakingBalance[beneficiary] / totalStakingBalance).
        uint256 userStake = stakingBalance[beneficiary];
        if (userStake == 0) {
            checkpoints[beneficiary] = block.number;
            return;
        }
        
        // Para evitar problemas de precisión, multiplicamos por 1e18 antes de dividir
        uint256 share = (userStake * 1e18) / totalStakingBalance;
        
        // Calcular las recompensas del usuario multiplicando la proporción por REWARD_PER_BLOCK y los bloques transcurridos.
        uint256 rewards = (REWARD_PER_BLOCK * blocksPassed * share) / 1e18;
        
        // Actualizar las recompensas pendientes del usuario en pendingRewards.
        pendingRewards[beneficiary] += rewards;
        
        // Actualizar el checkpoint del usuario al bloque actual.
        checkpoints[beneficiary] = block.number;
    }

    // Funciones adicionales útiles para consultas
    function getUserInfo(address user) external view returns (
        uint256 _stakingBalance,
        uint256 _pendingRewards,
        bool _hasStaked,
        bool _isStaking,
        uint256 _checkpoint
    ) {
        return (
            stakingBalance[user],
            pendingRewards[user],
            hasStaked[user],
            isStaking[user],
            checkpoints[user]
        );
    }

    function getStakersCount() external view returns (uint256) {
        return stakers.length;
    }
}