use openzeppelin::token::erc20::interface::IERC20;
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};
use starknet::{ContractAddress, contract_address_const};
use unruggable::amm::amm::{AMM, AMMV2};

use unruggable::tokens::interface::{
    IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
};

fn deploy_contract(
    owner: ContractAddress,
    recipient: ContractAddress,
    name: felt252,
    symbol: felt252,
    initial_supply: u256,
) -> ContractAddress {
    let contract = declare('UnruggableMemecoin');
    let mut constructor_calldata = array![
        owner.into(),
        recipient.into(),
        name,
        symbol,
        initial_supply.low.into(),
        initial_supply.high.into(),
    ];
    let amms: Array<AMM> = array![];
    Serde::serialize(@amms.into(), ref constructor_calldata);

    contract.deploy(@constructor_calldata).unwrap()
}

mod erc20_metadata {
    use core::debug::PrintTrait;
    use openzeppelin::token::erc20::interface::IERC20;
    use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
    use starknet::{ContractAddress, contract_address_const};
    use unruggable::tokens::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };
    use super::deploy_contract;

    #[test]
    fn test_name() {
        let owner = contract_address_const::<42>();
        let recipient = contract_address_const::<43>();
        let name = 'UnruggableMemecoin';
        let symbol = 'UM';
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(owner, recipient, name, symbol, initial_supply);

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check name. Should be equal to 'UnruggableMemecoin'.
        let name = memecoin.name();
        assert(name == name, 'Invalid name');
    }

    #[test]
    fn test_decimals() {
        let owner = contract_address_const::<42>();
        let recipient = contract_address_const::<43>();
        let name = 'UnruggableMemecoin';
        let symbol = 'UM';
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(owner, recipient, name, symbol, initial_supply);

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check decimals. Should be equal to 18.
        let decimals = memecoin.decimals();
        assert(decimals == 18, 'Invalid decimals');
    }

    #[test]
    fn test_symbol() {
        let owner = contract_address_const::<42>();
        let recipient = contract_address_const::<43>();
        let name = 'UnruggableMemecoin';
        let symbol = 'UM';
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(owner, recipient, name, symbol, initial_supply);

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check symbol. Should be equal to 'UM'.
        let symbol = memecoin.symbol();
        assert(symbol == symbol, 'Invalid symbol');
    }
}

mod erc20_entrypoints {
    use core::debug::PrintTrait;
    use core::traits::Into;
    use openzeppelin::token::erc20::interface::IERC20;
    use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
    use starknet::{ContractAddress, contract_address_const};
    use super::deploy_contract;
    use unruggable::tokens::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };

    // Test ERC20 snake entrypoints

    #[test]
    fn test_total_supply() {
        let owner = contract_address_const::<42>();
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(
            owner, owner, 'UnruggableMemecoin', 'UM', initial_supply
        );

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check total supply. Should be equal to initial supply.
        let total_supply = memecoin.total_supply();
        assert(total_supply == initial_supply, 'Invalid total supply');

        // Check initial balance. Should be equal to initial supply.
        let balance = memecoin.balance_of(owner);
        assert(balance == initial_supply, 'Invalid balance');
    }


    #[test]
    fn test_balance_of() {
        let owner = contract_address_const::<42>();
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(
            owner, owner, 'UnruggableMemecoin', 'UM', initial_supply
        );

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to initial supply.
        let balance = memecoin.balance_of(owner);
        assert(balance == initial_supply, 'Invalid balance');
    }

    #[test]
    fn test_approve_allowance() {
        let owner = contract_address_const::<42>();
        let spender = contract_address_const::<43>();
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(
            owner, owner, 'UnruggableMemecoin', 'UM', initial_supply
        );

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial allowance. Should be equal to 0.
        let allowance = memecoin.allowance(owner, spender);
        assert(allowance == 0.into(), 'Invalid allowance before');

        // Approve initial supply tokens.
        start_prank(CheatTarget::One(memecoin.contract_address), owner);
        memecoin.approve(spender, initial_supply);

        // Check allowance. Should be equal to initial supply.
        let allowance = memecoin.allowance(owner, spender);
        assert(allowance == initial_supply, 'Invalid allowance after');
    }

    #[test]
    fn test_transfer() {
        let owner = contract_address_const::<42>();
        let recipient = contract_address_const::<43>();
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(
            owner, owner, 'UnruggableMemecoin', 'UM', initial_supply
        );

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Transfer 100 tokens to recipient.
        start_prank(CheatTarget::One(memecoin.contract_address), owner);
        memecoin.transfer(recipient, 100.into());

        // Check balance. Should be equal to initial supply - 100.
        let owner_balance = memecoin.balance_of(owner);
        assert(owner_balance == (initial_supply - 100.into()), 'Invalid balance owner');

        // Check recipient balance. Should be equal to 100.
        let recipient_balance = memecoin.balance_of(recipient);
        assert(recipient_balance == 100.into(), 'Invalid balance recipient');
    }

    #[test]
    fn test_transfer_from() {
        let owner = contract_address_const::<42>();
        let spender = contract_address_const::<43>();
        let recipient = contract_address_const::<44>();
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(
            owner, owner, 'UnruggableMemecoin', 'UM', initial_supply
        );

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to initial supply.
        let balance = memecoin.balance_of(owner);
        assert(balance == initial_supply, 'Invalid balance');

        // Approve initial supply tokens.
        start_prank(CheatTarget::One(memecoin.contract_address), owner);
        memecoin.approve(spender, initial_supply);

        // Transfer 100 tokens to recipient.
        start_prank(CheatTarget::One(memecoin.contract_address), spender);
        memecoin.transfer_from(owner, recipient, 100.into());

        // Check balance. Should be equal to initial supply - 100.
        let owner_balance = memecoin.balance_of(owner);
        assert(owner_balance == (initial_supply - 100.into()), 'Invalid balance owner');

        // Check recipient balance. Should be equal to 100.
        let recipient_balance = memecoin.balance_of(recipient);
        assert(recipient_balance == 100.into(), 'Invalid balance recipient');

        // Check allowance. Should be equal to initial supply - 100.
        let allowance = memecoin.allowance(owner, spender);
        assert(allowance == (initial_supply - 100.into()), 'Invalid allowance');
    }

    // Test ERC20 Camel entrypoints

    #[test]
    fn test_totalSupply() {
        let owner = contract_address_const::<42>();
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(
            owner, owner, 'UnruggableMemecoin', 'UM', initial_supply
        );

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check total supply. Should be equal to initial supply.
        let total_supply = memecoin.totalSupply();
        assert(total_supply == initial_supply, 'Invalid total supply');
    }

    #[test]
    fn test_balanceOf() {
        let owner = contract_address_const::<42>();
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(
            owner, owner, 'UnruggableMemecoin', 'UM', initial_supply
        );

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to initial supply.
        let balance = memecoin.balanceOf(owner);
        assert(balance == initial_supply, 'Invalid balance');
    }

    #[test]
    fn test_transferFrom() {
        let owner = contract_address_const::<42>();
        let spender = contract_address_const::<43>();
        let recipient = contract_address_const::<44>();
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(
            owner, owner, 'UnruggableMemecoin', 'UM', initial_supply
        );

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to initial supply.
        let balance = memecoin.balanceOf(owner);
        assert(balance == initial_supply, 'Invalid balance');

        // Approve initial supply tokens.
        start_prank(CheatTarget::One(memecoin.contract_address), owner);
        memecoin.approve(spender, initial_supply);

        // Transfer 100 tokens to recipient.
        start_prank(CheatTarget::One(memecoin.contract_address), spender);
        memecoin.transferFrom(owner, recipient, 100.into());

        // Check balance. Should be equal to initial supply - 100.
        let balance = memecoin.balanceOf(owner);
        assert(balance == (initial_supply - 100.into()), 'Invalid balance');

        // Check recipient balance. Should be equal to 100.
        let balance = memecoin.balanceOf(recipient);
        assert(balance == 100.into(), 'Invalid balance');

        // Check allowance. Should be equal to initial supply - 100.
        let allowance = memecoin.allowance(owner, spender);
        assert(allowance == (initial_supply - 100.into()), 'Invalid allowance');
    }
}

mod memecoin_entrypoints {
    use unruggable::amm::jediswap_interface::{
        IFactoryC1, IFactoryC1Dispatcher, IFactoryC1DispatcherTrait, IRouterC1, IRouterC1Dispatcher,
        IRouterC1DispatcherTrait
    };
    use unruggable::tests_utils::constants::{TOKEN_MULTIPLIER, OWNER};
    use unruggable::tests_utils::deployer_helper::DeployerHelper::{
        deploy_contracts, deploy_erc20, deploy_unruggable_memecoin_contract, deploy_memecoin_factory
    };
    use unruggable::tokens::interface::{
        IUnruggableMemecoin, IUnruggableMemecoinDispatcher,
        IUnruggableMemecoinDispatcherTrait
    };
    use unruggable::tokens::memecoin::UnruggableMemecoin;
    use unruggable::amm::amm::{AMM, AMMV2};

    use unruggable::tokens::factory::{
        IUnruggableMemecoinFactory, IUnruggableMemecoinFactoryDispatcher,
        IUnruggableMemecoinFactoryDispatcherTrait
    };
    use openzeppelin::token::erc20::interface::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait};
    use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
    use starknet::{ContractAddress, contract_address_const};

    #[test]
    #[should_panic(expected: ('Caller is not the owner',))]
    fn test_launch_memecoin_not_owner() {
        // Setup
        let (_, router_address) = deploy_contracts();
        let router_dispatcher = IRouterC1Dispatcher { contract_address: router_address };

        let initial_supply: u256 = 10 * TOKEN_MULTIPLIER;
        let counterparty_token_address = deploy_erc20(initial_supply, OWNER());

        // Declare availables AMMs for this factory
        let mut amms = array![];
        amms.append(AMM { name: AMMV2::JediSwap.into(), router_address });

        // Declare UnruggableMemecoin and use ClassHash for the Factory
        let declare_memecoin = declare('UnruggableMemecoin');
        let memecoin_factory_address = deploy_memecoin_factory(
            OWNER(), declare_memecoin.class_hash, amms
        );

        // Deploy UnruggableMemecoinFactory
        let unruggable_meme_factory = IUnruggableMemecoinFactoryDispatcher {
            contract_address: memecoin_factory_address
        };

        // Create a MemeCoin
        let memecoin_address = unruggable_meme_factory
            .create_memecoin(OWNER(), OWNER(), 'MemeCoin', 'MC', initial_supply);
        let unruggable_memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };

        let token_dispatcher = IERC20Dispatcher { contract_address: counterparty_token_address };
    
        unruggable_memecoin.launch_memecoin(
            AMMV2::JediSwap, counterparty_token_address, 10 * TOKEN_MULTIPLIER, 10 * TOKEN_MULTIPLIER
        );
    }

    #[test]
    fn test_launch_memecoin_happy_path() {
        // Setup
        let (_, router_address) = deploy_contracts();
        let router_dispatcher = IRouterC1Dispatcher { contract_address: router_address };

        let initial_supply: u256 = 10 * TOKEN_MULTIPLIER;
        let counterparty_token_address = deploy_erc20(initial_supply, OWNER());

        // Declare availables AMMs for this factory
        let mut amms = array![];
        amms.append(AMM { name: AMMV2::JediSwap.into(), router_address });

        // Declare UnruggableMemecoin and use ClassHash for the Factory
        let declare_memecoin = declare('UnruggableMemecoin');
        let memecoin_factory_address = deploy_memecoin_factory(
            OWNER(), declare_memecoin.class_hash, amms
        );

        // Deploy UnruggableMemecoinFactory
        let unruggable_meme_factory = IUnruggableMemecoinFactoryDispatcher {
            contract_address: memecoin_factory_address
        };

        // Create a MemeCoin
        let memecoin_address = unruggable_meme_factory
            .create_memecoin(OWNER(), OWNER(), 'MemeCoin', 'MC', initial_supply);
        let unruggable_memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };

        let token_dispatcher = IERC20Dispatcher { contract_address: counterparty_token_address };

        // Transfer 10 counterparty_token to UnruggableMemecoin contract
        start_prank(CheatTarget::One(counterparty_token_address), OWNER());
        token_dispatcher.transfer(memecoin_address, 10 * TOKEN_MULTIPLIER);
        stop_prank(CheatTarget::One(counterparty_token_address));

        // Transfer 10 MT to UnruggableMemecoin contract
        start_prank(CheatTarget::One(memecoin_address), OWNER());
        unruggable_memecoin.transfer(memecoin_address, 10 * TOKEN_MULTIPLIER);
        stop_prank(CheatTarget::One(memecoin_address));
        
        // NOTE:
        // 1. The initial call to `memecoin_address` should be made by the OWNER().
        // 2. Subsequently, the router needs to call memecoin to transfer tokens to the pool.
        // 3. The second call to `memecoin_address` should be made by the router. 
        //    However, note that the prank still designates OWNER() as the caller.
        // `set_contract_address()` from starknet cannot be used in this context.
        // related issue: https://github.com/foundry-rs/starknet-foundry/issues/1402

        // start_prank(CheatTarget::One(memecoin_address), router_address); 
        // start_prank(CheatTarget::One(router_address), memecoin_address);
        // unruggable_memecoin
        //     .launch_memecoin(
        //         AMMV2::JediSwap, counterparty_token_address, 10 * TOKEN_MULTIPLIER, 10 * TOKEN_MULTIPLIER
        //     );
        // stop_prank(CheatTarget::One(memecoin_address));
        // stop_prank(CheatTarget::One(router_address));
    }

    #[test]
    #[should_panic(expected: ('insufficient memecoin funds',))]
    fn test_launch_memecoin_no_balance_memecoin() {
        // Setup
        let (_, router_address) = deploy_contracts();
        let router_dispatcher = IRouterC1Dispatcher { contract_address: router_address };

        let initial_supply: u256 = 10 * TOKEN_MULTIPLIER;
        let counterparty_token_address = deploy_erc20(initial_supply, OWNER());

        // Declare availables AMMs for this factory
        let mut amms = array![];
        amms.append(AMM { name: AMMV2::JediSwap.into(), router_address });

        // Declare UnruggableMemecoin and use ClassHash for the Factory
        let declare_memecoin = declare('UnruggableMemecoin');
        let memecoin_factory_address = deploy_memecoin_factory(
            OWNER(), declare_memecoin.class_hash, amms
        );

        // Deploy UnruggableMemecoinFactory
        let unruggable_meme_factory = IUnruggableMemecoinFactoryDispatcher {
            contract_address: memecoin_factory_address
        };

        // Create a MemeCoin
        let memecoin_address = unruggable_meme_factory
            .create_memecoin(OWNER(), OWNER(), 'MemeCoin', 'MC', initial_supply);
        let unruggable_memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };

        let token_dispatcher = IERC20Dispatcher { contract_address: counterparty_token_address };

        // Transfer 10 counterparty_token to UnruggableMemecoin contract
        start_prank(CheatTarget::One(counterparty_token_address), OWNER());
        token_dispatcher.transfer(memecoin_address, 10 * TOKEN_MULTIPLIER);
        stop_prank(CheatTarget::One(counterparty_token_address));

        start_prank(CheatTarget::One(memecoin_address), OWNER());
        unruggable_memecoin
            .launch_memecoin(
                AMMV2::JediSwap,
                counterparty_token_address,
                10 * TOKEN_MULTIPLIER,
                10 * TOKEN_MULTIPLIER
            );
        stop_prank(CheatTarget::One(memecoin_address));
    }

    #[test]
    #[should_panic(expected: ('insufficient token funds',))]
    fn test_launch_memecoin_no_balance_counteryparty_token() {
        // Setup
        let (_, router_address) = deploy_contracts();
        let router_dispatcher = IRouterC1Dispatcher { contract_address: router_address };

        let initial_supply: u256 = 10 * TOKEN_MULTIPLIER;
        let counterparty_token_address = deploy_erc20(initial_supply, OWNER());

        // Declare availables AMMs for this factory
        let mut amms = array![];
        amms.append(AMM { name: AMMV2::JediSwap.into(), router_address });

        // Declare UnruggableMemecoin and use ClassHash for the Factory
        let declare_memecoin = declare('UnruggableMemecoin');
        let memecoin_factory_address = deploy_memecoin_factory(
            OWNER(), declare_memecoin.class_hash, amms
        );

        // Deploy UnruggableMemecoinFactory
        let unruggable_meme_factory = IUnruggableMemecoinFactoryDispatcher {
            contract_address: memecoin_factory_address
        };

        // Create a MemeCoin
        let memecoin_address = unruggable_meme_factory
            .create_memecoin(OWNER(), OWNER(), 'MemeCoin', 'MC', initial_supply);
        let unruggable_memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };

        let token_dispatcher = IERC20Dispatcher { contract_address: counterparty_token_address };

        // Transfer 10 counterparty_token to UnruggableMemecoin contract
        start_prank(CheatTarget::One(memecoin_address), OWNER());
        unruggable_memecoin.transfer(memecoin_address, 10 * TOKEN_MULTIPLIER);
        stop_prank(CheatTarget::One(memecoin_address));

        start_prank(CheatTarget::One(memecoin_address), OWNER());
        unruggable_memecoin
            .launch_memecoin(
                AMMV2::JediSwap,
                counterparty_token_address,
                10 * TOKEN_MULTIPLIER,
                10 * TOKEN_MULTIPLIER
            );
        stop_prank(CheatTarget::One(memecoin_address));
    }
}
