// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TokenFarm is Ownable, ReentrancyGuard {
    // BONUS 2: Struct for user staking information
    struct UserInfo {
        uint256 stakingBalance;    // Amount of LP tokens staked
        uint256 checkpoint;        // Last block where rewards were calculated
        uint256 pendingRewards;    // Rewards waiting to be claimed
        bool hasStaked;           // Has the user ever staked
        bool isStaking;           // Is currently staking
    }

    // Tokens
    IERC20 public lpToken;
    IERC20 public dappToken;

    // BONUS 2: Single mapping with struct
    mapping(address => UserInfo) public users;
    address[] public stakers;

    // Farm configuration
    uint256 public rewardsPerBlock = 1e18; // BONUS 4: Variable rewards per block
    uint256 public totalStaked;
    uint256 public lastUpdateBlock;

    // BONUS 5: Withdrawal fee (2%)
    uint256 public withdrawalFee = 200; // 200 = 2% (in basis points)
    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public collectedFees;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsDistributed(uint256 totalRewards);
    event RewardsPerBlockUpdated(uint256 oldRate, uint256 newRate);
    event WithdrawalFeeUpdated(uint256 oldFee, uint256 newFee);
    event FeesWithdrawn(address indexed owner, uint256 amount);

    // BONUS 1: Modifiers
    modifier onlyStaker() {
        require(users[msg.sender].isStaking, "Not a staker");
        _;
    }

    modifier updateRewards(address user) {
        _updateUserRewards(user);
        _;
    }

    constructor(address _lpToken, address _dappToken) Ownable(msg.sender) {
        lpToken = IERC20(_lpToken);
        dappToken = IERC20(_dappToken);
        lastUpdateBlock = block.number;
    }

    // Deposit LP tokens for staking
    function deposit(uint256 amount) external nonReentrant updateRewards(msg.sender) {
        require(amount > 0, "Amount must be greater than 0");
        require(lpToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        UserInfo storage user = users[msg.sender];

        // Add to stakers array if first time staking
        if (!user.hasStaked) {
            stakers.push(msg.sender);
            user.hasStaked = true;
        }

        user.stakingBalance += amount;
        user.isStaking = true;
        totalStaked += amount;

        emit Deposit(msg.sender, amount);
    }

    // Withdraw all LP tokens
    function withdraw() external nonReentrant onlyStaker updateRewards(msg.sender) {
        UserInfo storage user = users[msg.sender];
        uint256 balance = user.stakingBalance;
        
        require(balance > 0, "No tokens to withdraw");

        user.stakingBalance = 0;
        user.isStaking = false;
        totalStaked -= balance;

        require(lpToken.transfer(msg.sender, balance), "Transfer failed");

        emit Withdraw(msg.sender, balance);
    }

    // Claim pending rewards
    function claimRewards() external nonReentrant updateRewards(msg.sender) {
        UserInfo storage user = users[msg.sender];
        uint256 rewards = user.pendingRewards;
        
        require(rewards > 0, "No rewards to claim");

        user.pendingRewards = 0;

        // BONUS 5: Apply withdrawal fee
        uint256 fee = (rewards * withdrawalFee) / FEE_DENOMINATOR;
        uint256 netRewards = rewards - fee;
        
        collectedFees += fee;

        require(dappToken.transfer(msg.sender, netRewards), "Reward transfer failed");

        emit RewardsClaimed(msg.sender, netRewards);
    }

    // Distribute rewards to all stakers
    function distributeRewardsAll() external onlyOwner {
        uint256 totalRewards = 0;
        
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            if (users[staker].isStaking) {
                _updateUserRewards(staker);
                totalRewards += users[staker].pendingRewards;
            }
        }

        emit RewardsDistributed(totalRewards);
    }

    // BONUS 4: Update rewards per block (only owner)
    function setRewardsPerBlock(uint256 _rewardsPerBlock) external onlyOwner {
        // Update all rewards before changing rate
        distributeRewardsAll();
        
        uint256 oldRate = rewardsPerBlock;
        rewardsPerBlock = _rewardsPerBlock;
        lastUpdateBlock = block.number;

        emit RewardsPerBlockUpdated(oldRate, _rewardsPerBlock);
    }

    // BONUS 5: Update withdrawal fee (only owner)
    function setWithdrawalFee(uint256 _withdrawalFee) external onlyOwner {
        require(_withdrawalFee <= 1000, "Fee too high"); // Max 10%
        
        uint256 oldFee = withdrawalFee;
        withdrawalFee = _withdrawalFee;

        emit WithdrawalFeeUpdated(oldFee, _withdrawalFee);
    }

    // BONUS 5: Withdraw collected fees (only owner)
    function withdrawFees() external onlyOwner {
        uint256 fees = collectedFees;
        require(fees > 0, "No fees to withdraw");
        
        collectedFees = 0;
        require(dappToken.transfer(msg.sender, fees), "Fee transfer failed");

        emit FeesWithdrawn(msg.sender, fees);
    }

    // Internal function to update user rewards
    function _updateUserRewards(address userAddress) internal {
        UserInfo storage user = users[userAddress];
        
        if (user.stakingBalance > 0) {
            uint256 blocksPassed = block.number - user.checkpoint;
            uint256 rewards = (user.stakingBalance * rewardsPerBlock * blocksPassed) / totalStaked;
            user.pendingRewards += rewards;
        }
        
        user.checkpoint = block.number;
    }

    // View functions
    function getUserInfo(address userAddress) external view returns (
        uint256 stakingBalance,
        uint256 pendingRewards,
        bool hasStaked,
        bool isStaking
    ) {
        UserInfo memory user = users[userAddress];
        
        // Calculate current pending rewards
        uint256 currentPending = user.pendingRewards;
        if (user.stakingBalance > 0 && totalStaked > 0) {
            uint256 blocksPassed = block.number - user.checkpoint;
            uint256 newRewards = (user.stakingBalance * rewardsPerBlock * blocksPassed) / totalStaked;
            currentPending += newRewards;
        }

        return (
            user.stakingBalance,
            currentPending,
            user.hasStaked,
            user.isStaking
        );
    }

    function getStakersCount() external view returns (uint256) {
        return stakers.length;
    }

    function getTotalValueLocked() external view returns (uint256) {
        return totalStaked;
    }
}