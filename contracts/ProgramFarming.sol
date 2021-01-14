// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.4;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
// Note that it's ownable and the owner wields tremendous power. The ownership
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
*/
contract ProgramFarming is Ownable {
    using SafeMath for uint256;

    trcToken private programID = 1000495;

    struct UserInfo {
        uint256 amount;     // How many TRX the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // The block number when Program farming starts.
    uint256[] public phases;
    uint256 public lastRewardBlock;

    uint256 internal accProgramPerShare;  // Accumulated ProgramToken per share, times 1e12. See below.


    // Bonus multiplier for early prg makers.
    uint256 internal constant BONUS_MULTIPLIER_1 = 20; // first 10,512,000 blocks - 2,0`Program in Block
    uint256 internal constant BONUS_MULTIPLIER_2 = 10; // next  10,512,000 blocks - 1,0 Program in Block
    uint256 internal constant BONUS_MULTIPLIER_3 = 5; //  next  10,512,000 blocks - 0,5 Program in BLock
    uint256 internal constant BONUS_MULTIPLIER_4 = 3; //  last  77,360,000 blocks - 0,3 Program in Block

    uint256 public programPerBlock = 100000; // 0,1 PRGRM

    // Info of each user that stakes TRX.
    mapping (address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(uint256 _startBlock) public {
        phases.push(_startBlock);// start 1 year
        phases.push(phases[0].add(10512000));// start 2 year
        phases.push(phases[1].add(10512000));// start 3 year
        phases.push(phases[2].add(10512000)); // start 4 year
        phases.push(phases[3].add(77360000));// end 10 year
    }


    function setProgramPerBlock(uint256 _newAmount) public onlyOwner{
        programPerBlock = _newAmount;
    }


    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= phases[0]) {
            return  _to.sub(_from);
        }
        else if (_to <= phases[1]) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER_1);
        }
        else if (_to <= phases[2]) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER_2);
        }
        else if (_to <= phases[3]) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER_3);
        }
        else if (_to <= phases[4]) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER_4);
        }
        else if (_from >= phases[4]) {
            return _to.sub(_from);
        }
        else {
            return phases[4].sub(_from).mul(BONUS_MULTIPLIER_1).add(_to.sub(phases[4]));
        }
    }


    // View current block reward in ProgramTokens
    function getCurrentBlockReward() public view returns (uint256) {
        return programPerBlock;
    }


    // View function to see pending ProgramTokens on frontend.
    function pendingProgram(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 programPerShare = accProgramPerShare;
        uint256 trxSupply = address(this).balance;

        if (block.number > lastRewardBlock && trxSupply != 0) {
            uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
            uint256 programReward = (multiplier.mul(1e5));
            programPerShare = programPerShare.add(programReward.mul(1e12).div(trxSupply));
        }
        return user.amount.mul(programPerShare).div(1e12).sub(user.rewardDebt);
    }


    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 trxSupply = address(this).balance;
        if (trxSupply == 0) {
              lastRewardBlock = block.number;
              return;
        }

        uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
        uint256 programReward = multiplier.mul(1e5);
        accProgramPerShare = accProgramPerShare.add(programReward.mul(1e12).div(trxSupply));
        lastRewardBlock = block.number;
    }


    // Deposit TRX
    function deposit() public payable {
        uint256 _amount = msg.value;
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accProgramPerShare).div(1e12).sub(user.rewardDebt);
            safeProgramTransfer(msg.sender, pending); // transfer Program
        }
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(accProgramPerShare).div(1e12);
        emit Deposit(msg.sender, _amount);
    }


    // Withdraw TRX from Interstellar.
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();
        uint256 pending = user.amount.mul(accProgramPerShare).div(1e12).sub(user.rewardDebt);
        safeProgramTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(accProgramPerShare).div(1e12);
        msg.sender.transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }


    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        msg.sender.transfer(user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }


    // Safe ProgramTokens transfer function, just in case if rounding error causes pool to not have enough ProgramTokens.
     function safeProgramTransfer(address payable _to, uint256 _amount) internal {
        uint256 programBalance = address(this).tokenBalance(programID);
        if (_amount > programBalance) {
            _to.transferToken(programBalance, programID);
        } else {
            _to.transferToken(_amount, programID);
        }
     }

}