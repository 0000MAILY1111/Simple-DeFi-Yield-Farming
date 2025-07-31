Caso de uso
En este ejercicio, implementarás un proyecto DeFi simple de Token Farm.

La Farm debe permitir a los usuarios realizar depósitos y retiros de un token mock LP.
Los usuarios también pueden reclamar las recompensas generadas durante el staking. Estas recompensas son tokens de la plataforma: nombre: "DApp Token", token: "DAPP".
El contrato contiene el marco y comentarios necesarios para implementar el contrato. Sigue los comentarios indicados para completarlo.

El caso de uso del contrato Simple Token Farm es el siguiente:

Los usuarios depositan tokens LP con la función deposit().
Los usuarios pueden recolectar o reclamar recompensas con la función claimRewards().
Los usuarios pueden deshacer el staking de todos sus tokens LP con la función withdraw(), pero aún pueden reclamar las recompensas pendientes.
Cada vez que se actualiza la cantidad de tokens LP en staking, las recompensas deben recalcularse primero.
El propietario de la plataforma puede llamar al método distributeRewardsAll() a intervalos regulares para actualizar las recompensas pendientes de todos los usuarios en staking.
Contratos
LPToken.sol: Contrato del token LP, utilizado para el staking.
DappToken.sol: Contrato del token de la plataforma, utilizado como recompensa.
TokenFarm.sol: Contrato de la Farm.
Requisitos
Crear un nuevo proyecto Hardhat e incluir el contrato proporcionado.
Implementar todas las funciones, eventos y cualquier otro elemento mencionado en los comentarios del código.
Desplegar los contratos en un entorno local.



DAppToken at 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8          
LPToken at 0xf8e81D47203A594245E36C48e151709F0C19fBe8             
TokenFarm at  0x9D7f74d0C41E726EC95884E0e97Fa6129e3b5E99

mas info contacte a mayxuz :D
