///sepolia 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title TokenFarm
 * @notice Contrato de farming DeFi completamente autónomo sin dependencias externas
 */
contract TokenFarm {
    // Variables de estado principales
    string public name = "Proportional Token Farm";
    address public owner;
    
    // Direcciones de los contratos de tokens
    address public dappTokenAddress;
    address public lpTokenAddress;
    
    // Configuración de recompensas
    uint256 public constant REWARD_PER_BLOCK = 1e18; // 1 token por bloque total
    uint256 public totalStakingBalance; // Total de tokens LP en staking
    
    // Arrays y mappings para rastrear usuarios
    address[] public stakers;
    
    mapping(address => uint256) public stakingBalance;    // Balance en staking por usuario
    mapping(address => uint256) public checkpoints;      // Último bloque calculado por usuario
    mapping(address => uint256) public pendingRewards;   // Recompensas pendientes por usuario
    mapping(address => bool) public hasStaked;           // Si el usuario ha hecho staking alguna vez
    mapping(address => bool) public isStaking;           // Si el usuario está actualmente en staking

    // Eventos del sistema
    event Deposit(address indexed usuario, uint256 cantidad);
    event Withdraw(address indexed usuario, uint256 cantidad);
    event RewardsClaimed(address indexed usuario, uint256 cantidad);
    event RewardsDistributed(uint256 totalUsuarios);

    // Modifiers de seguridad
    modifier soloOwner() {
        require(msg.sender == owner, "Solo el propietario puede ejecutar esta funcion");
        _;
    }
    
    modifier usuarioEnStaking() {
        require(isStaking[msg.sender], "El usuario no esta haciendo staking");
        _;
    }

    // Constructor
    constructor(address _dappToken, address _lpToken) {
        require(_dappToken != address(0), "Direccion de DappToken invalida");
        require(_lpToken != address(0), "Direccion de LPToken invalida");
        
        dappTokenAddress = _dappToken;
        lpTokenAddress = _lpToken;
        owner = msg.sender;
    }

    /**
     * @notice Deposita tokens LP para hacer staking
     * @param _amount Cantidad de tokens LP a depositar
     */
    function deposit(uint256 _amount) external {
        require(_amount > 0, "La cantidad debe ser mayor a 0");
        
        // Llamar al contrato LP Token para transferir
        (bool success, ) = lpTokenAddress.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), _amount)
        );
        require(success, "Transferencia de LP tokens fallida");
        
        // Si el usuario ya está en staking, actualizar recompensas primero
        if (isStaking[msg.sender]) {
            distributeRewards(msg.sender);
        }
        
        // Actualizar balances
        stakingBalance[msg.sender] += _amount;
        totalStakingBalance += _amount;
        
        // Agregar a la lista de stakers si es primera vez
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
            hasStaked[msg.sender] = true;
        }
        
        // Marcar como activo en staking
        isStaking[msg.sender] = true;
        
        // Establecer checkpoint
        checkpoints[msg.sender] = block.number;
        
        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice Retira todos los tokens LP del staking
     */
    function withdraw() external usuarioEnStaking {
        uint256 balance = stakingBalance[msg.sender];
        require(balance > 0, "No hay tokens para retirar");
        
        // Actualizar recompensas antes del retiro
        distributeRewards(msg.sender);
        
        // Actualizar estados
        stakingBalance[msg.sender] = 0;
        totalStakingBalance -= balance;
        isStaking[msg.sender] = false;
        
        // Transferir tokens LP de vuelta al usuario
        (bool success, ) = lpTokenAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", msg.sender, balance)
        );
        require(success, "Transferencia de LP tokens fallida");
        
        emit Withdraw(msg.sender, balance);
    }

    /**
     * @notice Reclama todas las recompensas pendientes
     */
    function claimRewards() external {
        // Actualizar recompensas si está en staking
        if (isStaking[msg.sender]) {
            distributeRewards(msg.sender);
        }
        
        uint256 pendingAmount = pendingRewards[msg.sender];
        require(pendingAmount > 0, "No hay recompensas pendientes");
        
        // Resetear recompensas pendientes
        pendingRewards[msg.sender] = 0;
        
        // Mintear tokens DAPP como recompensa
        (bool success, ) = dappTokenAddress.call(
            abi.encodeWithSignature("mint(address,uint256)", msg.sender, pendingAmount)
        );
        require(success, "Minteo de recompensas fallido");
        
        emit RewardsClaimed(msg.sender, pendingAmount);
    }

    /**
     * @notice Distribuye recompensas a todos los usuarios activos (solo owner)
     */
    function distributeRewardsAll() external soloOwner {
        uint256 usuariosActualizados = 0;
        
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            if (isStaking[staker]) {
                distributeRewards(staker);
                usuariosActualizados++;
            }
        }
        
        emit RewardsDistributed(usuariosActualizados);
    }

    /**
     * @notice Calcula y actualiza las recompensas de un usuario específico
     * @param beneficiary Dirección del usuario para calcular recompensas
     */
    function distributeRewards(address beneficiary) private {
        uint256 lastCheckpoint = checkpoints[beneficiary];
        
        // Verificar condiciones para calcular recompensas
        if (block.number <= lastCheckpoint || totalStakingBalance == 0 || stakingBalance[beneficiary] == 0) {
            return;
        }
        
        // Calcular bloques transcurridos
        uint256 blocksPassed = block.number - lastCheckpoint;
        
        // Calcular proporción del usuario (con precisión)
        uint256 userShare = (stakingBalance[beneficiary] * 1e18) / totalStakingBalance;
        
        // Calcular recompensas del usuario
        uint256 userReward = (REWARD_PER_BLOCK * blocksPassed * userShare) / 1e18;
        
        // Actualizar recompensas pendientes y checkpoint
        pendingRewards[beneficiary] += userReward;
        checkpoints[beneficiary] = block.number;
    }

    // Funciones de vista para consultar estado
    function getStakersCount() external view returns (uint256) {
        return stakers.length;
    }
    
    function getUserInfo(address usuario) external view returns (
        uint256 balanceStaking,
        uint256 recompensasPendientes,
        bool estaHaciendoStaking,
        bool haHechoStaking
    ) {
        return (
            stakingBalance[usuario],
            pendingRewards[usuario],
            isStaking[usuario],
            hasStaked[usuario]
        );
    }
    
    function calculatePendingRewards(address usuario) external view returns (uint256) {
        if (!isStaking[usuario] || totalStakingBalance == 0 || stakingBalance[usuario] == 0) {
            return pendingRewards[usuario];
        }
        
        uint256 lastCheckpoint = checkpoints[usuario];
        if (block.number <= lastCheckpoint) {
            return pendingRewards[usuario];
        }
        
        uint256 blocksPassed = block.number - lastCheckpoint;
        uint256 userShare = (stakingBalance[usuario] * 1e18) / totalStakingBalance;
        uint256 newReward = (REWARD_PER_BLOCK * blocksPassed * userShare) / 1e18;
        
        return pendingRewards[usuario] + newReward;
    }
    
    // Función administrativa
    function transferOwnership(address newOwner) external soloOwner {
        require(newOwner != address(0), "Nuevo propietario no puede ser direccion cero");
        owner = newOwner;
    }
}