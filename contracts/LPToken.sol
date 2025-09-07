///sepolia 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title LPToken
 * @notice Token ERC20 nativo para representar tokens de liquidez
 */
contract LPToken {
    // Variables básicas del token
    string public name = "LP Token";
    string public symbol = "LPT";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    // Control de acceso
    address public owner;
    
    // Mappings ERC20
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    // Eventos ERC20
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // Modifier de seguridad
    modifier soloOwner() {
        require(msg.sender == owner, "Solo el propietario puede ejecutar esta funcion");
        _;
    }
    
    // Constructor
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    /**
     * @notice Transfiere tokens del caller a otra dirección
     */
    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "No se puede transferir a direccion cero");
        require(balanceOf[msg.sender] >= amount, "Balance insuficiente");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    /**
     * @notice Aprueba a un spender para gastar tokens en nombre del caller
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    /**
     * @notice Transfiere tokens de una dirección a otra usando allowance
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(to != address(0), "No se puede transferir a direccion cero");
        require(balanceOf[from] >= amount, "Balance insuficiente");
        require(allowance[from][msg.sender] >= amount, "Allowance insuficiente");
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
    
    /**
     * @notice Mintea nuevos tokens (solo owner)
     */
    function mint(address to, uint256 amount) external soloOwner {
        require(to != address(0), "No se puede mintear a direccion cero");
        
        totalSupply += amount;
        balanceOf[to] += amount;
        
        emit Transfer(address(0), to, amount);
    }
    
    /**
     * @notice Transfiere la propiedad del contrato
     */
    function transferOwnership(address newOwner) external soloOwner {
        require(newOwner != address(0), "Nuevo propietario no puede ser direccion cero");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}