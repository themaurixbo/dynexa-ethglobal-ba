// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import {TestFtsoV2Interface} from "@flarenetwork/flare-periphery-contracts/coston2/TestFtsoV2Interface.sol";
import {ContractRegistry} from "@flarenetwork/flare-periphery-contracts/coston2/ContractRegistry.sol";
import {IFeeCalculator} from "@flarenetwork/flare-periphery-contracts/coston2/IFeeCalculator.sol";

contract AutoYieldWallet {
    TestFtsoV2Interface public ftso;
    bytes21 public constant flrUsdId = 0x01464c522f55534400000000000000000000000000;
    
    mapping(address => uint256) public userShares;
    mapping(address => uint256) public userDeposits;
    uint256 public totalStaked;
    uint256 public totalShares;
    uint256 public constant MIN_STAKE_AMOUNT = 0.1 ether;
    
    address public owner;
    
    event Deposited(address indexed user, uint256 amount, uint256 shares);
    event Withdrawn(address indexed user, uint256 amount, uint256 shares);
    event Staked(uint256 amount);
    event Unstaked(uint256 amount);
    event RewardsClaimed(uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier minimumAmount(uint256 amount) {
        require(amount >= MIN_STAKE_AMOUNT, "Amount too low");
        _;
    }
    
    
    constructor() {
        owner = msg.sender;
        ftso = ContractRegistry.getTestFtsoV2();
    }
       
    /**
     * @notice Depositar FLR y auto-stakear
     */
    function deposit() external payable minimumAmount(msg.value) {
        uint256 amount = msg.value;
        
        // Calcular shares (1:1 inicialmente)
        uint256 shares = amount;
        
        userShares[msg.sender] += shares;
        userDeposits[msg.sender] += amount;
        totalShares += shares;
        
        _stake(amount);
        
        emit Deposited(msg.sender, amount, shares);
    }
    
    /**
     * @notice Retirar parcialmente
     * @param shareAmount Cantidad de shares a retirar
     */
    function withdraw(uint256 shareAmount) external {
        require(shareAmount > 0, "Cannot withdraw 0");
        require(userShares[msg.sender] >= shareAmount, "Insufficient shares");
        
        // Calcular equivalente en FLR
        uint256 flrAmount = (shareAmount * address(this).balance) / totalShares;
        
        // Actualizar balances
        userShares[msg.sender] -= shareAmount;
        totalShares -= shareAmount;
        userDeposits[msg.sender] -= flrAmount;
        
        // Unstake si es necesario
        if (address(this).balance < flrAmount) {
            uint256 needed = flrAmount - address(this).balance;
            _unstake(needed);
        }
        
        // Transferir al usuario
        payable(msg.sender).transfer(flrAmount);
        
        emit Withdrawn(msg.sender, flrAmount, shareAmount);
    }
    
    
    
    /**
     * @notice Obtener precio actual de FLR/USD
     */
    function getFLRPrice() public view returns (uint256 price, int8 decimals, uint64 timestamp) {
        return ftso.getFeedById(flrUsdId);
    }
    
    /**
     * @notice Obtener balance del usuario en FLR
     */
    function getUserBalance(address user) public view returns (uint256) {
        if (totalShares == 0) return 0;
        return (userShares[user] * address(this).balance) / totalShares;
    }
    
    /**
     * @notice Obtener TVL (Total Value Locked)
     */
    function getTVL() public view returns (uint256) {
        return address(this).balance;
    }
        
    function _stake(uint256 amount) internal {
        totalStaked += amount;
        emit Staked(amount);
        
    }
    
    function _unstake(uint256 amount) internal {
        require(totalStaked >= amount, "Insufficient staked");
        
        totalStaked -= amount;
        emit Unstaked(amount);
        
        console.log("Unstaked %s FLR", amount / 1e18);
    }
    
    function _claimRewards() internal {
        uint256 simulatedRewards = totalStaked / 100; 
        emit RewardsClaimed(simulatedRewards);
        
        console.log("Claimed %s FLR in rewards", simulatedRewards / 1e18);
    }
    
    
    // ========== FALLBACK ==========
    receive() external payable {
        // Auto-stakear cuando llegan fondos
        if (msg.value >= MIN_STAKE_AMOUNT) {
            _stake(msg.value);
        }
    }
}