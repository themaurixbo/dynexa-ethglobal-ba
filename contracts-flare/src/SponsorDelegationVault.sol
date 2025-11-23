// SPDX-License-Identifier: MIT
  pragma solidity ^0.8.20;

  import {ContractRegistry} from "@flarenetwork/flare-periphery-contracts/coston2/ContractRegistry.sol";
  import {TestFtsoV2Interface} from "@flarenetwork/flare-periphery-contracts/coston2/TestFtsoV2Interface.sol";

  interface IWNat {
      function deposit() external payable;
      function withdraw(uint256 amount) external;
      function delegate(address to, uint256 bips) external;
      function undelegateAll() external;
      function balanceOf(address account) external view returns (uint256);
  }

  /**
   * @title SponsorVault
   * @notice Empresas depositan FLR, delegan y ganan rewards
   */
  contract SponsorDelegationVault {


      IWNat public wNat;
      address public owner;
      address public dataProvider;

      bytes21 public constant FLR_USD_ID = 0x01464c522f55534400000000000000000000000000;

      struct Company {
          string name;
          uint256 deposited;
          uint256 delegated;
          bool registered;
      }

      mapping(address => Company) public companies;
      address[] public companyList;

      uint256 public totalDeposited;
      uint256 public totalDelegated;


      event CompanyRegistered(address indexed company, string name);
      event Deposited(address indexed company, uint256 amount);
      event Delegated(address indexed company, uint256 amount);
      event Withdrawn(address indexed company, uint256 amount);


      constructor(address _wNat, address _dataProvider) {
          owner = msg.sender;
          wNat = IWNat(_wNat);
          dataProvider = _dataProvider;
      }


      modifier onlyRegistered() {
          require(companies[msg.sender].registered, "Not registered");
          _;
      }


      function register(string calldata _name) external {
          require(!companies[msg.sender].registered, "Already registered");
          
          companies[msg.sender] = Company({
              name: _name,
              deposited: 0,
              delegated: 0,
              registered: true
          });
          
          companyList.push(msg.sender);
          emit CompanyRegistered(msg.sender, _name);
      }

      function depositAndDelegate() external payable onlyRegistered {
          require(msg.value > 0, "Amount must be > 0");

          Company storage c = companies[msg.sender];
          c.deposited += msg.value;
          c.delegated += msg.value;
          totalDeposited += msg.value;
          totalDelegated += msg.value;

          wNat.deposit{value: msg.value}();
          wNat.delegate(dataProvider, 10000);

          emit Deposited(msg.sender, msg.value);
          emit Delegated(msg.sender, msg.value);
      }

      function withdrawAll() external onlyRegistered {
          Company storage c = companies[msg.sender];
          uint256 amount = c.delegated;
          require(amount > 0, "Nothing to withdraw");

          totalDelegated -= c.delegated;
          totalDeposited -= c.deposited;
          c.delegated = 0;
          c.deposited = 0;

          wNat.undelegateAll();
          wNat.withdraw(amount);

          (bool success, ) = payable(msg.sender).call{value: amount}("");
          require(success, "Transfer failed");

          emit Withdrawn(msg.sender, amount);
      }

      function withdraw(uint256 _amount) external onlyRegistered {
          Company storage c = companies[msg.sender];
          require(c.delegated >= _amount, "Insufficient balance");

          c.delegated -= _amount;
          c.deposited -= _amount;
          totalDelegated -= _amount;
          totalDeposited -= _amount;

          wNat.undelegateAll();
          wNat.withdraw(_amount);

          if (c.delegated > 0) {
              wNat.delegate(dataProvider, 10000);
          }

          (bool success, ) = payable(msg.sender).call{value: _amount}("");
          require(success, "Transfer failed");

          emit Withdrawn(msg.sender, _amount);
      }


      function getFlrPrice() public view returns (uint256 price, int8 decimals) {
          TestFtsoV2Interface ftsoV2 = ContractRegistry.getTestFtsoV2();
          (price, decimals, ) = ftsoV2.getFeedById(FLR_USD_ID);
      }

      function getValueUSD(uint256 _flrAmount) public view returns (uint256) {
          (uint256 price, int8 dec) = getFlrPrice();
          if (dec >= 0) {
              return (_flrAmount * price) / (10 ** uint8(dec));
          }
          return (_flrAmount * price) * (10 ** uint8(-dec));
      }


      function getCompanyInfo(address _company) external view returns (
          string memory name,
          uint256 deposited,
          uint256 delegated,
          uint256 valueUSD,
          bool registered
      ) {
          Company storage c = companies[_company];
          return (c.name, c.deposited, c.delegated, getValueUSD(c.delegated), c.registered);
      }

      function getSystemStats() external view returns (
          uint256 _totalDeposited,
          uint256 _totalDelegated,
          uint256 _totalValueUSD,
          uint256 _flrPrice,
          uint256 _companyCount
      ) {
          (uint256 price, ) = getFlrPrice();
          return (totalDeposited, totalDelegated, getValueUSD(totalDelegated), price, companyList.length);
      }

      function getAllCompanies() external view returns (address[] memory) {
          return companyList;
      }

      function getContractBalance() external view returns (uint256) {
          return wNat.balanceOf(address(this));
      }


      function setDataProvider(address _newProvider) external {
          require(msg.sender == owner, "Not owner");
          dataProvider = _newProvider;
      }

      receive() external payable {}
  }