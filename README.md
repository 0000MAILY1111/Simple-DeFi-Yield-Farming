# 🌾 Simple DeFi Yield Farming

## 📋 Descripción del Proyecto

Este proyecto implementa un sistema completo de **Yield Farming DeFi** que permite a los usuarios hacer staking de tokens LP y ganar recompensas de manera proporcional a su participación en el pool total.

El sistema funciona de manera similar a las farms de **PancakeSwap**, donde los usuarios depositan tokens de liquidez (LP tokens) y reciben recompensas en tokens de la plataforma (DAPP tokens) basadas en la cantidad de bloques transcurridos y su proporción del staking total.

## 🎯 Caso de Uso

### Flujo Principal
1. **Depósito**: Los usuarios depositan tokens LP usando `deposit()`
2. **Generación de Recompensas**: Las recompensas se acumulan automáticamente por bloque de manera proporcional
3. **Reclamo**: Los usuarios pueden reclamar recompensas con `claimRewards()`
4. **Retiro**: Los usuarios pueden retirar todos sus tokens LP con `withdraw()`
5. **Distribución Global**: El owner puede actualizar recompensas de todos los usuarios con `distributeRewardsAll()`

### Características Principales
- ✅ **Staking Proporcional**: Las recompensas se distribuyen según la participación de cada usuario
- ✅ **Sistema de Checkpoints**: Evita recálculos innecesarios y optimiza gas
- ✅ **Contratos Autónomos**: Sin dependencias externas como OpenZeppelin
- ✅ **Modifiers de Seguridad**: Validaciones de acceso y estado
- ✅ **Eventos Completos**: Tracking completo de todas las operaciones
- ✅ **Contrato de Pruebas**: Testing automatizado integrado

## 🏗️ Arquitectura del Sistema

### Contratos Principales

| Contrato | Descripción | Función |
|----------|-------------|---------|
| **DAppToken.sol** | Token ERC20 de recompensas | Token "DAPP" que se mintea como recompensa |
| **LPToken.sol** | Token ERC20 de liquidez | Token "LPT" que los usuarios stakean |
| **TokenFarm.sol** | Contrato principal de farming | Lógica de staking y distribución de recompensas |
| **TokenFarmTester.sol** | Contrato de pruebas | Testing automatizado del sistema completo |

### Cálculo de Recompensas

```solidity
// Fórmula de recompensas proporcionales
userShare = (stakingBalance[user] * 1e18) / totalStakingBalance
userReward = (REWARD_PER_BLOCK * blocksPassed * userShare) / 1e18
```

**Ejemplo Práctico:**
- Usuario A: 100 LP tokens stakeados (25% del total)
- Usuario B: 300 LP tokens stakeados (75% del total)
- Total pool: 400 LP tokens
- Recompensa por bloque: 1 DAPP token
- Bloques transcurridos: 10

**Resultado:**
- Usuario A: 2.5 DAPP tokens (10 bloques × 1 DAPP × 0.25)
- Usuario B: 7.5 DAPP tokens (10 bloques × 1 DAPP × 0.75)

## 🚀 Implementación

### Contratos Desplegados en Sepolia

| Contrato | Dirección | Verificado |
|----------|-----------|------------|
| **DAppToken** | `0xfa5260Bc8db90B606abA6095A3D9A10a96Db3ba4` | ✅ |
| **LPToken** | `0x35d23ca102AfD4D89Fe234632d2D1539A87Ae497` | ✅ |
| **TokenFarm** | `0x218f64A022Ab905946A9798F05f5b45dCFaD57B2` | ✅ |
| **TokenFarmTester** | `0xCdAc4914D2592a628c7590A78a97ac1F47fe32AD` | ✅ |

**🔗 Contrato Verificado:** [Ver en Etherscan](https://sepolia.etherscan.io/verifyContract-solc?a=0xcdac4914d2592a628c7590a78a97ac1f47fe32ad&c=v0.8.30%2bcommit.73712a01&lictype=3)

### Configuración del Proyecto

#### Prerequisitos
- Node.js v18+
- Hardhat
- MetaMask configurado para Sepolia
- Fondos de prueba ETH en Sepolia

#### Instalación Local

```bash
# Clonar el repositorio
git clone https://github.com/0000MAILY1111/Simple-DeFi-Yield-Farming
cd Simple-DeFi-Yield-Farming

# Instalar dependencias
npm install

# Configurar variables de entorno
cp .env.example .env
# Editar .env con tu PRIVATE_KEY y RPC_URL

# Compilar contratos
npx hardhat compile

# Ejecutar tests
npx hardhat test

# Desplegar en red local
npx hardhat node
npx hardhat run scripts/deploy.js --network localhost

# Desplegar en Sepolia
npx hardhat run scripts/deploy.js --network sepolia
```

### Despliegue Manual en Remix

1. **Preparar Archivos**: Copiar los 4 contratos en Remix IDE
2. **Compilar**: Seleccionar Solidity 0.8.18+
3. **Desplegar en Orden**:
   ```javascript
   // 1. DAppToken()
   // 2. LPToken()
   // 3. TokenFarm(direccionDAppToken, direccionLPToken)
   // 4. dappToken.transferOwnership(direccionTokenFarm)
   // 5. TokenFarmTester(direccionTokenFarm, direccionDAppToken, direccionLPToken)
   ```

## 🧪 Testing y Uso

### Prueba Rápida con Tester Contract

```javascript
// 1. Configurar usuario con 1000 LP tokens
tokenFarmTester.setupUsuario(tuDireccion, "1000000000000000000000")

// 2. Ejecutar flujo completo de farming con 100 LP tokens
tokenFarmTester.pruebaFlujoDeFarmingCompleto("100000000000000000000")

// 3. Ver estado del usuario
tokenFarmTester.mostrarEstadoUsuario(tuDireccion)
```

### Flujo Manual Paso a Paso

```javascript
// 1. Mintear LP tokens para testing
lpToken.mint(tuDireccion, "1000000000000000000000") // 1000 LPT

// 2. Aprobar gasto al farm
lpToken.approve(direccionTokenFarm, "100000000000000000000") // 100 LPT

// 3. Hacer depósito
tokenFarm.deposit("100000000000000000000") // 100 LPT

// 4. Esperar bloques o hacer transacciones para generar recompensas

// 5. Verificar recompensas pendientes
tokenFarm.calculatePendingRewards(tuDireccion)

// 6. Reclamar recompensas
tokenFarm.claimRewards()

// 7. Retirar tokens LP
tokenFarm.withdraw()
```

## 🎁 Características Bonus Implementadas

### ✅ Bonus 1: Modifiers de Seguridad
```solidity
modifier soloOwner() {
    require(msg.sender == owner, "Solo el propietario puede ejecutar esta funcion");
    _;
}

modifier usuarioEnStaking() {
    require(isStaking[msg.sender], "El usuario no esta haciendo staking");
    _;
}
```

### ✅ Bonus 3: Contratos de Prueba
- Contrato `TokenFarmTester` con pruebas automatizadas
- Funciones de testing para cada operación
- Sistema de eventos para tracking de resultados

### 🔄 Bonus Disponibles para Implementar

#### Bonus 2: Sistema de Struct
```solidity
struct UsuarioInfo {
    uint256 stakingBalance;
    uint256 checkpoints;
    uint256 pendingRewards;
    bool hasStaked;
    bool isStaking;
}
mapping(address => UsuarioInfo) public usuarios;
```

#### Bonus 4: Recompensas Variables
```solidity
uint256 public rewardPerBlock = 1e18;
function setRewardPerBlock(uint256 _newRate) external soloOwner {
    rewardPerBlock = _newRate;
}
```

#### Bonus 5: Comisión de Retiro
```solidity
uint256 public constant FEE_PERCENTAGE = 300; // 3%
uint256 public accumulatedFees;

function claimRewardsWithFee() external {
    uint256 fee = (pendingAmount * FEE_PERCENTAGE) / 10000;
    accumulatedFees += fee;
    dappToken.mint(msg.sender, pendingAmount - fee);
}
```

## 📊 Métricas del Sistema

### Gas Costs Estimados
| Función | Gas Estimado |
|---------|--------------|
| `deposit()` | ~80,000 gas |
| `withdraw()` | ~60,000 gas |
| `claimRewards()` | ~50,000 gas |
| `distributeRewardsAll()` | ~50,000 × número de usuarios |

### Límites del Sistema
- **Recompensa por bloque**: 1 DAPP token fijo
- **Precisión decimal**: 18 decimales
- **Usuarios máximos**: Sin límite (limitado por gas block)
- **Tokens soportados**: LP tokens específicos

## 🔒 Seguridad

### Características de Seguridad Implementadas
- ✅ **Validación de direcciones cero**
- ✅ **Verificación de balances antes de transfers**
- ✅ **Modifiers de acceso restrictivo**
- ✅ **Prevención de reentrancy** (uso de checks-effects-interactions)
- ✅ **Validación de parámetros de entrada**

### Consideraciones de Seguridad
⚠️ **Nota**: Este es un proyecto educativo. Para producción considerar:
- Auditorías de seguridad profesionales
- Implementación de pausa de emergencia
- Límites de rate limiting
- Multi-signature para funciones administrativas

## 📚 Referencias y Recursos

### Documentación DeFi
- [PancakeSwap Farms Documentation](https://docs.pancakeswap.finance/products/yield-farming/how-to-use-farms)
- [Solidity Documentation](https://docs.soliditylang.org/)
- [Hardhat Documentation](https://hardhat.org/docs)

### Código Fuente
- **Repositorio Original**: [Gist de referencia](https://gist.github.com/luisvid/5a87ce5690451e965bb3c86f37a3cfbd)
- **Repositorio del Proyecto**: [GitHub](https://github.com/0000MAILY1111/Simple-DeFi-Yield-Farming)

## 👥 Contribuciones y Contacto

### Desarrollador Principal
**Contacto**: mayxuz

### Cómo Contribuir
1. Fork el repositorio
2. Crear una rama para tu feature (`git checkout -b feature/nueva-caracteristica`)
3. Commit tus cambios (`git commit -am 'Añadir nueva característica'`)
4. Push a la rama (`git push origin feature/nueva-caracteristica`)
5. Crear un Pull Request

### Issues y Soporte
- Reportar bugs en [GitHub Issues](https://github.com/0000MAILY1111/Simple-DeFi-Yield-Farming/issues)
- Para consultas técnicas contactar a **mayxuz**

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.

---

## 🚀 Quick Start

```bash
# Clonación rápida y setup
git clone https://github.com/0000MAILY1111/Simple-DeFi-Yield-Farming
cd Simple-DeFi-Yield-Farming
npm install
npx hardhat test

# O prueba directamente en Sepolia con los contratos desplegados
# Dirección del Tester: 0xCdAc4914D2592a628c7590A78a97ac1F47fe32AD
```

**¡Empieza a hacer yield farming ahora mismo! 🌾💰**
