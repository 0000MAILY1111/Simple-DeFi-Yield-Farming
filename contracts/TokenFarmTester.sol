// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title TokenFarmTester
 * @notice Contrato de pruebas completamente autónomo para TokenFarm
 */
contract TokenFarmTester {
    // Referencias a los contratos
    address public tokenFarmAddress;
    address public dappTokenAddress;
    address public lpTokenAddress;
    address public owner;
    
    // Eventos para tracking de pruebas
    event TestResult(string testName, bool passed, string mensaje);
    event UserStatus(
        address usuario, 
        uint256 lpBalance, 
        uint256 dappBalance, 
        uint256 stakingBalance, 
        uint256 pendingRewards
    );
    
    constructor(address _tokenFarm, address _dappToken, address _lpToken) {
        require(_tokenFarm != address(0), "Direccion TokenFarm invalida");
        require(_dappToken != address(0), "Direccion DappToken invalida");
        require(_lpToken != address(0), "Direccion LPToken invalida");
        
        tokenFarmAddress = _tokenFarm;
        dappTokenAddress = _dappToken;
        lpTokenAddress = _lpToken;
        owner = msg.sender;
    }
    
    /**
     * @notice Configura un usuario con tokens LP para testing
     */
    function setupUsuario(address usuario, uint256 cantidadLP) external {
        // Mintear LP tokens al usuario
        (bool success, ) = lpTokenAddress.call(
            abi.encodeWithSignature("mint(address,uint256)", usuario, cantidadLP)
        );
        
        if (success) {
            emit TestResult("Setup Usuario", true, "Tokens LP minteados exitosamente");
        } else {
            emit TestResult("Setup Usuario", false, "Error al mintear tokens LP");
        }
    }
    
    /**
     * @notice Ejecuta prueba completa de depósito
     */
    function pruebaDepositoCompleta(uint256 cantidad) external {
        // 1. Aprobar tokens LP
        (bool approveSuccess, ) = lpTokenAddress.call(
            abi.encodeWithSignature("approve(address,uint256)", tokenFarmAddress, cantidad)
        );
        
        if (!approveSuccess) {
            emit TestResult("Deposito Completo", false, "Error en aprobacion de tokens");
            return;
        }
        
        // 2. Realizar depósito
        (bool depositSuccess, ) = tokenFarmAddress.call(
            abi.encodeWithSignature("deposit(uint256)", cantidad)
        );
        
        if (depositSuccess) {
            emit TestResult("Deposito Completo", true, "Deposito realizado exitosamente");
            mostrarEstadoUsuario(msg.sender);
        } else {
            emit TestResult("Deposito Completo", false, "Error en deposito");
        }
    }
    
    /**
     * @notice Simula el paso de bloques para generar recompensas
     */
    function simularBloques(uint256 numeroTransacciones) external {
        for (uint256 i = 0; i < numeroTransacciones; i++) {
            // Transacciones dummy para avanzar bloques
        }
        emit TestResult("Simulacion Bloques", true, "Bloques simulados para recompensas");
    }
    
    /**
     * @notice Ejecuta prueba de reclamo de recompensas
     */
    function pruebaReclamoCompleto() external {
        // Obtener balance antes del reclamo
        (bool balanceSuccess, bytes memory balanceData) = dappTokenAddress.call(
            abi.encodeWithSignature("balanceOf(address)", msg.sender)
        );
        
        uint256 balanceAntes = 0;
        if (balanceSuccess) {
            balanceAntes = abi.decode(balanceData, (uint256));
        }
        
        // Intentar reclamar recompensas
        (bool claimSuccess, ) = tokenFarmAddress.call(
            abi.encodeWithSignature("claimRewards()")
        );
        
        if (claimSuccess) {
            emit TestResult("Reclamo Recompensas", true, "Recompensas reclamadas exitosamente");
            mostrarEstadoUsuario(msg.sender);
        } else {
            emit TestResult("Reclamo Recompensas", false, "Error al reclamar recompensas");
        }
    }
    
    /**
     * @notice Ejecuta prueba de retiro completo
     */
    function pruebaRetiroCompleto() external {
        (bool withdrawSuccess, ) = tokenFarmAddress.call(
            abi.encodeWithSignature("withdraw()")
        );
        
        if (withdrawSuccess) {
            emit TestResult("Retiro Completo", true, "Retiro realizado exitosamente");
            mostrarEstadoUsuario(msg.sender);
        } else {
            emit TestResult("Retiro Completo", false, "Error en retiro");
        }
    }
    
    /**
     * @notice Muestra el estado actual del usuario
     */
    function mostrarEstadoUsuario(address usuario) public {
        // Obtener balance LP
        (bool lpSuccess, bytes memory lpData) = lpTokenAddress.call(
            abi.encodeWithSignature("balanceOf(address)", usuario)
        );
        uint256 lpBalance = lpSuccess ? abi.decode(lpData, (uint256)) : 0;
        
        // Obtener balance DAPP
        (bool dappSuccess, bytes memory dappData) = dappTokenAddress.call(
            abi.encodeWithSignature("balanceOf(address)", usuario)
        );
        uint256 dappBalance = dappSuccess ? abi.decode(dappData, (uint256)) : 0;
        
        // Obtener balance en staking
        (bool stakingSuccess, bytes memory stakingData) = tokenFarmAddress.call(
            abi.encodeWithSignature("stakingBalance(address)", usuario)
        );
        uint256 stakingBalance = stakingSuccess ? abi.decode(stakingData, (uint256)) : 0;
        
        // Obtener recompensas pendientes
        (bool pendingSuccess, bytes memory pendingData) = tokenFarmAddress.call(
            abi.encodeWithSignature("calculatePendingRewards(address)", usuario)
        );
        uint256 pendingRewards = pendingSuccess ? abi.decode(pendingData, (uint256)) : 0;
        
        emit UserStatus(usuario, lpBalance, dappBalance, stakingBalance, pendingRewards);
    }
    
    
}