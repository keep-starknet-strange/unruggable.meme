use openzeppelin::token::erc20::interface::IERC20;
use openzeppelin::utils::serde::SerializedAppend;
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, RevertedTransaction};
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
    initial_holders: Span<ContractAddress>,
    initial_holders_amounts: Span<u256>,
) -> Result<ContractAddress, RevertedTransaction> {
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

    Serde::serialize(@initial_holders.into(), ref constructor_calldata);
    Serde::serialize(@initial_holders_amounts.into(), ref constructor_calldata);
    contract.deploy(@constructor_calldata)
}

fn instantiate_params() -> (
    ContractAddress,
    ContractAddress,
    felt252,
    felt252,
    u256,
    ContractAddress,
    ContractAddress,
    Span<ContractAddress>,
    Span<u256>,
) {
    let owner = contract_address_const::<42>();
    let recipient = contract_address_const::<43>();
    let name = 'UnruggableMemecoin';
    let symbol = 'UM';
    let initial_supply = 1000.into();
    let initial_holder_1 = contract_address_const::<44>();
    let initial_holder_2 = contract_address_const::<45>();
    let initial_holders = array![recipient, initial_holder_1, initial_holder_2].span();
    let initial_holders_amounts = array![900.into(), 50.into(), 50.into()].span();
    (
        owner,
        recipient,
        name,
        symbol,
        initial_supply,
        initial_holder_1,
        initial_holder_2,
        initial_holders,
        initial_holders_amounts
    )
}

mod erc20_metadata {
    use core::debug::PrintTrait;
    use openzeppelin::token::erc20::interface::IERC20;
    use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
    use starknet::{ContractAddress, contract_address_const};
    use super::{deploy_contract, instantiate_params};
    use unruggable::tokens::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };

    #[test]
    fn test_name() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        // let initial_holders = array![recipient, initial_holder_1, initial_holder_2].span();
        // let initial_holders_amounts = array![900.into(), 50.into(), 50.into()].span();
        let contract_address =
            match deploy_contract(
                owner,
                recipient,
                name,
                symbol,
                initial_supply,
                initial_holders,
                initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check name. Should be equal to 'UnruggableMemecoin'.
        let name = memecoin.name();
        assert(name == 'UnruggableMemecoin', 'Invalid name');
    }

    #[test]
    fn test_decimals() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let contract_address =
            match deploy_contract(
                owner,
                recipient,
                name,
                symbol,
                initial_supply,
                initial_holders,
                initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check decimals. Should be equal to 18.
        let decimals = memecoin.decimals();
        assert(decimals == 18, 'Invalid decimals');
    }
    #[test]
    fn test_symbol() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let contract_address =
            match deploy_contract(
                owner,
                recipient,
                name,
                symbol,
                initial_supply,
                initial_holders,
                initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };
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
    use super::{deploy_contract, instantiate_params};
    use unruggable::tokens::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };

    // Test ERC20 snake entrypoints

    #[test]
    fn test_total_supply() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let contract_address =
            match deploy_contract(
                owner,
                recipient,
                name,
                symbol,
                initial_supply,
                initial_holders,
                initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check total supply. Should be equal to initial supply.
        let total_supply = memecoin.total_supply();
        assert(total_supply == initial_supply, 'Invalid total supply');
    }

    #[test]
    fn test_balance_of() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let contract_address =
            match deploy_contract(
                owner,
                recipient,
                name,
                symbol,
                initial_supply,
                initial_holders,
                initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial recipient balance. Should be equal to 900.
        let balance = memecoin.balance_of(recipient);
        assert(balance == 900, 'Invalid balance');
        // Check initial holder 1 balance. Should be equal to 50.
        let balance = memecoin.balance_of(initial_holder_1);
        assert(balance == 50, 'Invalid balance');
        // Check initial holder 2 balance. Should be equal to 50.
        let balance = memecoin.balance_of(initial_holder_1);
        assert(balance == 50, 'Invalid balance');
    }

    #[test]
    fn test_approve_allowance() {
        let (
            owner,
            spender,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            _,
            initial_holders_amounts
        ) =
            instantiate_params();
        let initial_holders = array![owner, initial_holder_1, initial_holder_2].span();
        let contract_address =
            match deploy_contract(
                owner, owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

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
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            _,
            initial_holders_amounts
        ) =
            instantiate_params();
        let initial_holders = array![owner, initial_holder_1, initial_holder_2].span();
        let contract_address =
            match deploy_contract(
                owner, owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Transfer 100 tokens to recipient.
        start_prank(CheatTarget::One(memecoin.contract_address), owner);
        memecoin.transfer(recipient, 20.into());

        // Check balance. Should be equal to initial supply - initial distrib (50 each) - 20.
        let owner_balance = memecoin.balance_of(owner);
        assert(owner_balance == (900 - 20.into()), 'Invalid balance owner');

        // Check recipient balance. Should be equal to 100.
        let recipient_balance = memecoin.balance_of(recipient);
        assert(recipient_balance == 20.into(), 'Invalid balance recipient');
    }

    #[test]
    fn test_transfer_from() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            _,
            initial_holders_amounts
        ) =
            instantiate_params();
        let spender = contract_address_const::<46>();
        let initial_holders = array![owner, initial_holder_1, initial_holder_2].span();
        let contract_address =
            match deploy_contract(
                owner, owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to initial supply - initial distrib of 2*50.
        let balance = memecoin.balance_of(owner);
        assert(balance == 900, 'Invalid balance');

        // Approve initial supply tokens.
        start_prank(CheatTarget::One(memecoin.contract_address), owner);
        memecoin.approve(spender, initial_supply);

        // Transfer 100 tokens to recipient.
        start_prank(CheatTarget::One(memecoin.contract_address), spender);
        memecoin.transfer_from(owner, recipient, 20.into());

        // Check balance. Should be equal to initial supply - 100.
        let owner_balance = memecoin.balance_of(owner);
        assert(owner_balance == (initial_supply - 2 * 50 - 20.into()), 'Invalid balance owner');

        // Check recipient balance. Should be equal to 100.
        let recipient_balance = memecoin.balance_of(recipient);
        assert(recipient_balance == 20.into(), 'Invalid balance recipient');

        // Check allowance. Should be equal to initial supply - transfered amount.
        let allowance = memecoin.allowance(owner, spender);
        assert(allowance == (initial_supply - 20.into()), 'Invalid allowance');
    }

    // Test ERC20 Camel entrypoints

    #[test]
    fn test_totalSupply() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let contract_address =
            match deploy_contract(
                owner,
                recipient,
                name,
                symbol,
                initial_supply,
                initial_holders,
                initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check total supply. Should be equal to initial supply.
        let total_supply = memecoin.totalSupply();
        assert(total_supply == initial_supply, 'Invalid total supply');
    }
    #[test]
    fn test_balanceOf() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            _,
            initial_holders_amounts
        ) =
            instantiate_params();
        let initial_holders = array![owner, initial_holder_1, initial_holder_2].span();
        let contract_address =
            match deploy_contract(
                owner, owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial recipient balance. Should be equal to 900.
        let balance = memecoin.balanceOf(owner);
        assert(balance == 900, 'Invalid balance');
        // Check initial holder 1 balance. Should be equal to 50.
        let balance = memecoin.balanceOf(initial_holder_1);
        assert(balance == 50, 'Invalid balance');
        // Check initial holder 2 balance. Should be equal to 50.
        let balance = memecoin.balanceOf(initial_holder_1);
        assert(balance == 50, 'Invalid balance');
    }
    #[test]
    fn test_transferFrom() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            _,
            initial_holders_amounts
        ) =
            instantiate_params();
        let initial_holders = array![owner, initial_holder_1, initial_holder_2].span();
        let spender = contract_address_const::<46>();
        let contract_address =
            match deploy_contract(
                owner, owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to initial supply.
        let balance = memecoin.balanceOf(owner);
        assert(balance == (initial_supply - 2 * 50), 'Invalid balance');

        // Approve initial supply tokens.
        start_prank(CheatTarget::One(memecoin.contract_address), owner);
        memecoin.approve(spender, initial_supply);

        // Transfer 100 tokens to recipient.
        start_prank(CheatTarget::One(memecoin.contract_address), spender);
        memecoin.transferFrom(owner, recipient, 100.into());

        // Check balance. Should be equal to initial supply - 100.
        let balance = memecoin.balanceOf(owner);
        assert(balance == (initial_supply - 2 * 50 - 100.into()), 'Invalid balance');

        // Check recipient balance. Should be equal to 100.
        let balance = memecoin.balanceOf(recipient);
        assert(balance == 100.into(), 'Invalid balance');

        // Check allowance. Should be equal to initial supply - 100.
        let allowance = memecoin.allowance(owner, spender);
        assert(allowance == (initial_supply - 100.into()), 'Invalid allowance');
    }
}

mod memecoin_entrypoints {
    use debug::PrintTrait;

    use openzeppelin::token::erc20::interface::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait};
    use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
    use starknet::{ContractAddress, contract_address_const};
    use super::{deploy_contract, instantiate_params};
    use unruggable::amm::amm::{AMM, AMMV2};
    use unruggable::amm::jediswap_interface::{
        IFactoryC1, IFactoryC1Dispatcher, IFactoryC1DispatcherTrait, IRouterC1, IRouterC1Dispatcher,
        IRouterC1DispatcherTrait
    };
    use unruggable::tests_utils::deployer_helper::DeployerHelper::{
        deploy_contracts, deploy_erc20, deploy_unruggable_memecoin_contract, deploy_memecoin_factory
    };

    use unruggable::tokens::factory::{
        IUnruggableMemecoinFactory, IUnruggableMemecoinFactoryDispatcher,
        IUnruggableMemecoinFactoryDispatcherTrait
    };
    use unruggable::tokens::interface::{
        IUnruggableMemecoin, IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };
    use unruggable::tokens::memecoin::UnruggableMemecoin;

    const TOKEN_MULTIPLIER: u256 = 1000000000000000000;

    // #[test]
    // fn test_launch_memecoin() {
    //     let (
    //         owner,
    //         recipient,
    //         name,
    //         symbol,
    //         initial_supply,
    //         initial_holder_1,
    //         initial_holder_2,
    //         initial_holders,
    //         initial_holders_amounts
    //     ) =
    //         instantiate_params();
    //     let contract_address =
    //         match deploy_contract(
    //             owner,
    //             recipient,
    //             name,
    //             symbol,
    //             initial_supply,
    //             initial_holders,
    //             initial_holders_amounts
    //         ) {
    //         Result::Ok(address) => address,
    //         Result::Err(msg) => panic(msg.panic_data),
    //     };

    //     let memecoin = IUnruggableMemecoinDispatcher { contract_address };

    //     start_prank(CheatTarget::One(memecoin.contract_address), owner);
    //     memecoin.launch_memecoin();

    //     assert(memecoin.launched(), 'Coin not launched');
    // }

    #[test]
    #[should_panic(expected: ('Caller is not the owner',))]
    fn test_launch_memecoin_not_owner() {
        // Setup
        let (_, router_address) = deploy_contracts();
        let router_dispatcher = IRouterC1Dispatcher { contract_address: router_address };
        let (owner, recipient, name, symbol, _, _, initial_holder_2, _, _) = instantiate_params();
        let initial_holders = array![owner].span();
        let initial_holders_amounts = array![1 * TOKEN_MULTIPLIER].span();

        let initial_supply: u256 = 100 * TOKEN_MULTIPLIER;
        let counterparty_token_address = deploy_erc20(initial_supply, owner);

        // Declare availables AMMs for this factory
        let mut amms = array![AMM { name: AMMV2::JediSwap.into(), router_address }];

        // Declare UnruggableMemecoin and use ClassHash for the Factory
        let declare_memecoin = declare('UnruggableMemecoin');
        let memecoin_factory_address = deploy_memecoin_factory(
            owner, declare_memecoin.class_hash, amms
        );

        // Deploy UnruggableMemecoinFactory
        let unruggable_meme_factory = IUnruggableMemecoinFactoryDispatcher {
            contract_address: memecoin_factory_address
        };

        // Create a MemeCoin
        let memecoin_address = unruggable_meme_factory
            .create_memecoin(
                owner, owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            );
        let unruggable_memecoin = IUnruggableMemecoinDispatcher {
            contract_address: memecoin_address
        };
        let token_dispatcher = IERC20Dispatcher { contract_address: counterparty_token_address };

        unruggable_memecoin
            .launch_memecoin(
                AMMV2::JediSwap,
                counterparty_token_address,
                1 * TOKEN_MULTIPLIER,
                1 * TOKEN_MULTIPLIER
            );
    }

    #[test]
    fn test_launch_memecoin_happy_path() {
        // Setup
        let (_, router_address) = deploy_contracts();
        let router_dispatcher = IRouterC1Dispatcher { contract_address: router_address };
        let (owner, recipient, name, symbol, _, _, _, _, _) = instantiate_params();
        let initial_holders = array![owner].span();
        let initial_holders_amounts = array![1 * TOKEN_MULTIPLIER].span();

        let initial_supply: u256 = 100 * TOKEN_MULTIPLIER;
        let counterparty_token_address = deploy_erc20(initial_supply, owner);

        // Declare availables AMMs for this factory
        let mut amms = array![AMM { name: AMMV2::JediSwap.into(), router_address }];

        // Declare UnruggableMemecoin and use ClassHash for the Factory
        let declare_memecoin = declare('UnruggableMemecoin');
        let memecoin_factory_address = deploy_memecoin_factory(
            owner, declare_memecoin.class_hash, amms
        );

        // Deploy UnruggableMemecoinFactory
        let unruggable_meme_factory = IUnruggableMemecoinFactoryDispatcher {
            contract_address: memecoin_factory_address
        };

        // Create a MemeCoin
        let memecoin_address = unruggable_meme_factory
            .create_memecoin(
                owner, owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            );
        let unruggable_memecoin = IUnruggableMemecoinDispatcher {
            contract_address: memecoin_address
        };

        let token_dispatcher = IERC20Dispatcher { contract_address: counterparty_token_address };

        // Transfer 1 counterparty_token to UnruggableMemecoin contract
        start_prank(CheatTarget::One(counterparty_token_address), owner);
        token_dispatcher.transfer(memecoin_address, 1 * TOKEN_MULTIPLIER);
        stop_prank(CheatTarget::One(counterparty_token_address));

        // Transfer 0.02 (2% of 100 * TOKEN_MULTIPLIER) memecoin to UnruggableMemecoin contract
        start_prank(CheatTarget::One(memecoin_address), owner);
        unruggable_memecoin.transfer(memecoin_address, 20000000000000000);
        stop_prank(CheatTarget::One(memecoin_address));
    // NOTE:
    // 1. The initial call to `memecoin_address` should be made by the owner.
    // 2. Subsequently, the router needs to call memecoin to transfer tokens to the pool.
    // 3. The second call to `memecoin_address` should be made by the router. 
    //    However, note that the prank still designates owner as the caller.
    // `set_contract_address()` from starknet cannot be used in this context.
    // related issue: https://github.com/foundry-rs/starknet-foundry/issues/1402

    // start_prank(CheatTarget::One(memecoin_address), router_address); 
    // start_prank(CheatTarget::One(router_address), memecoin_address);
    // unruggable_memecoin
    //     .launch_memecoin(
    //         AMMV2::JediSwap, counterparty_token_address, 20000000000000000, 1 * TOKEN_MULTIPLIER
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
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            _,
            initial_holders_amounts
        ) =
            instantiate_params();
        let initial_holders = array![owner].span();
        let initial_holders_amounts = array![1 * TOKEN_MULTIPLIER].span();

        let initial_supply: u256 = 100 * TOKEN_MULTIPLIER;
        let counterparty_token_address = deploy_erc20(initial_supply, owner);

        // Declare availables AMMs for this factory
        let mut amms = array![AMM { name: AMMV2::JediSwap.into(), router_address }];

        // Declare UnruggableMemecoin and use ClassHash for the Factory
        let declare_memecoin = declare('UnruggableMemecoin');
        let memecoin_factory_address = deploy_memecoin_factory(
            owner, declare_memecoin.class_hash, amms
        );

        // Deploy UnruggableMemecoinFactory
        let unruggable_meme_factory = IUnruggableMemecoinFactoryDispatcher {
            contract_address: memecoin_factory_address
        };

        // Create a MemeCoin
        let memecoin_address = unruggable_meme_factory
            .create_memecoin(
                owner, owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            );
        let unruggable_memecoin = IUnruggableMemecoinDispatcher {
            contract_address: memecoin_address
        };

        let token_dispatcher = IERC20Dispatcher { contract_address: counterparty_token_address };

        // Transfer 1 counterparty_token to UnruggableMemecoin contract
        start_prank(CheatTarget::One(counterparty_token_address), owner);
        token_dispatcher.transfer(memecoin_address, 1 * TOKEN_MULTIPLIER);
        stop_prank(CheatTarget::One(counterparty_token_address));

        start_prank(CheatTarget::One(memecoin_address), owner);
        unruggable_memecoin
            .launch_memecoin(
                AMMV2::JediSwap,
                counterparty_token_address,
                1 * TOKEN_MULTIPLIER,
                1 * TOKEN_MULTIPLIER
            );
        stop_prank(CheatTarget::One(memecoin_address));
    }

    #[test]
    #[should_panic(expected: ('insufficient token funds',))]
    fn test_launch_memecoin_no_balance_counteryparty_token() {
        // Setup
        let (_, router_address) = deploy_contracts();
        let router_dispatcher = IRouterC1Dispatcher { contract_address: router_address };
        let (owner, recipient, name, symbol, _, _, _, _, _) = instantiate_params();
        let initial_holders = array![owner].span();
        let initial_holders_amounts = array![1 * TOKEN_MULTIPLIER].span();

        let initial_supply: u256 = 100 * TOKEN_MULTIPLIER;
        let counterparty_token_address = deploy_erc20(initial_supply, owner);

        // Declare availables AMMs for this factory
        let mut amms = array![];
        amms.append(AMM { name: AMMV2::JediSwap.into(), router_address });

        // Declare UnruggableMemecoin and use ClassHash for the Factory
        let declare_memecoin = declare('UnruggableMemecoin');
        let memecoin_factory_address = deploy_memecoin_factory(
            owner, declare_memecoin.class_hash, amms
        );

        // Deploy UnruggableMemecoinFactory
        let unruggable_meme_factory = IUnruggableMemecoinFactoryDispatcher {
            contract_address: memecoin_factory_address
        };

        // Create a MemeCoin
        let memecoin_address = unruggable_meme_factory
            .create_memecoin(
                owner, owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            );
        let unruggable_memecoin = IUnruggableMemecoinDispatcher {
            contract_address: memecoin_address
        };

        let token_dispatcher = IERC20Dispatcher { contract_address: counterparty_token_address };

        // Transfer 0.02 (2% of 100 * TOKEN_MULTIPLIER) memecoin to UnruggableMemecoin contract
        start_prank(CheatTarget::One(memecoin_address), owner);
        unruggable_memecoin.transfer(memecoin_address, 20000000000000000);
        stop_prank(CheatTarget::One(memecoin_address));

        start_prank(CheatTarget::One(memecoin_address), owner);
        unruggable_memecoin
            .launch_memecoin(
                AMMV2::JediSwap, counterparty_token_address, 20000000000000000, 20000000000000000
            );
        stop_prank(CheatTarget::One(memecoin_address));
    }

    #[test]
    fn test_get_team_allocation() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let contract_address =
            match deploy_contract(
                owner,
                recipient,
                name,
                symbol,
                initial_supply,
                initial_holders,
                initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        let team_alloc = memecoin.get_team_allocation();
        // theorical team allocation is 10%, so initial_supply * MAX_TEAM_ALLOC / 100
        // 1000 * 100 / 100 = 100
        assert(team_alloc == 100, 'Invalid team allocation');
    }

    #[test]
    #[should_panic(expected: ('Max buy cap reached',))]
    fn test_transfer_max_percentage() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            _,
            initial_holders_amounts
        ) =
            instantiate_params();
        let alice = contract_address_const::<53>();
        let initial_holders = array![owner, initial_holder_1, initial_holder_2].span();

        let contract_address =
            match deploy_contract(
                owner, owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to initial supply.
        let balance = memecoin.balance_of(owner);
        assert(balance == initial_supply - 100, 'Invalid balance');

        // Transfer 1 token from owner to alice.
        start_prank(CheatTarget::One(memecoin.contract_address), owner);
        let send_amount = memecoin.transfer(alice, 500);
        assert(memecoin.balance_of(alice) == 500.into(), 'Invalid balance');
    }


    #[test]
    #[should_panic(expected: ('Max buy cap reached',))]
    fn test_transfer_from_max_percentage() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            _,
            initial_holders_amounts
        ) =
            instantiate_params();
        let alice = contract_address_const::<53>();
        let initial_holders = array![owner, initial_holder_1, initial_holder_2].span();

        let contract_address =
            match deploy_contract(
                owner, owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to initial supply.
        let balance = memecoin.balance_of(owner);
        assert(balance == initial_supply - 100, 'Invalid balance');

        // Transfer 1 token from owner to alice.
        start_prank(CheatTarget::One(memecoin.contract_address), owner);
        let send_amount = memecoin.transfer_from(owner, alice, 500);
        assert(memecoin.balance_of(alice) == 500.into(), 'Invalid balance');
    }

    #[test]
    fn test_classic_max_percentage() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            _,
            initial_holders_amounts
        ) =
            instantiate_params();
        let alice = contract_address_const::<53>();
        let initial_holders = array![owner, initial_holder_1, initial_holder_2].span();

        let contract_address =
            match deploy_contract(
                owner, owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to initial supply.
        let balance = memecoin.balance_of(owner);
        assert(balance == initial_supply - 100, 'Invalid balance');

        // Transfer 1 token from owner to alice.
        start_prank(CheatTarget::One(memecoin.contract_address), owner);
        let send_amount = memecoin.transfer(alice, 10.into());
        assert(memecoin.balance_of(alice) == 10.into(), 'Invalid balance');
    }
}

mod custom_constructor {
    use core::debug::PrintTrait;
    use openzeppelin::token::erc20::interface::IERC20;
    use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
    use starknet::{ContractAddress, contract_address_const};
    use super::{deploy_contract, instantiate_params};
    use unruggable::tokens::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };

    #[test]
    #[should_panic(expected: ('Unruggable: arrays len dif',))]
    fn test_constructor_initial_holders_arrays_len_mismatch() {
        let (
            owner, recipient, name, symbol, initial_supply, initial_holder_1, initial_holder_2, _, _
        ) =
            instantiate_params();
        let initial_holder_3 = contract_address_const::<52>();
        let initial_holder_4 = contract_address_const::<53>();
        let initial_holders = array![
            recipient, initial_holder_1, initial_holder_2, initial_holder_3, initial_holder_4
        ]
            .span();
        let initial_holders_amounts = array![900.into(), 50.into(), 40.into(), 10.into()].span();
        match deploy_contract(
            owner, recipient, name, symbol, initial_supply, initial_holders, initial_holders_amounts
        ) {
            Result::Ok(address) => address.print(),
            Result::Err(msg) => panic(msg.panic_data),
        }
    }
    #[test]
    fn test_constructor_initial_holders_arrays_len_is_equal() {
        let (
            owner, recipient, name, symbol, initial_supply, initial_holder_1, initial_holder_2, _, _
        ) =
            instantiate_params();
        let initial_holder_3 = contract_address_const::<52>();
        // array_len is 4
        let initial_holders = array![
            recipient, initial_holder_1, initial_holder_2, initial_holder_3
        ]
            .span();
        // array_len is 4
        let initial_holders_amounts = array![900.into(), 50.into(), 40.into(), 10.into()].span();
        match deploy_contract(
            owner, recipient, name, symbol, initial_supply, initial_holders, initial_holders_amounts
        ) {
            Result::Ok(address) => {},
            Result::Err(msg) => panic(msg.panic_data),
        }
    }
    #[test]
    #[should_panic(expected: ('Unruggable: max holders reached',))]
    fn test_max_holders_reached() {
        let (
            owner, recipient, name, symbol, initial_supply, initial_holder_1, initial_holder_2, _, _
        ) =
            instantiate_params();
        let initial_holder_3 = contract_address_const::<52>();
        let initial_holder_4 = contract_address_const::<53>();
        let initial_holder_5 = contract_address_const::<54>();
        let initial_holder_6 = contract_address_const::<55>();
        let initial_holder_7 = contract_address_const::<56>();
        let initial_holder_8 = contract_address_const::<57>();
        let initial_holder_9 = contract_address_const::<58>();
        let initial_holder_10 = contract_address_const::<59>();
        // 11 holders
        let initial_holders = array![
            recipient,
            initial_holder_1,
            initial_holder_2,
            initial_holder_3,
            initial_holder_4,
            initial_holder_5,
            initial_holder_6,
            initial_holder_7,
            initial_holder_8,
            initial_holder_9,
            initial_holder_10,
        ]
            .span();
        let initial_holders_amounts = array![
            900.into(),
            50.into(),
            42.into(),
            1.into(),
            1.into(),
            1.into(),
            1.into(),
            1.into(),
            1.into(),
            1.into(),
            1.into(),
        ]
            .span();

        match deploy_contract(
            owner, recipient, name, symbol, initial_supply, initial_holders, initial_holders_amounts
        ) {
            Result::Ok(address) => address.print(),
            Result::Err(msg) => panic(msg.panic_data),
        }
    }
    #[test]
    fn test_max_holders_not_reached() {
        let (
            owner, recipient, name, symbol, initial_supply, initial_holder_1, initial_holder_2, _, _
        ) =
            instantiate_params();
        let initial_holder_3 = contract_address_const::<52>();
        let initial_holder_4 = contract_address_const::<53>();
        let initial_holder_5 = contract_address_const::<54>();
        // 6 holders
        let initial_holders = array![
            recipient,
            initial_holder_1,
            initial_holder_2,
            initial_holder_3,
            initial_holder_4,
            initial_holder_5,
        ]
            .span();
        let initial_holders_amounts = array![
            900.into(), 50.into(), 47.into(), 1.into(), 1.into(), 1.into(),
        ]
            .span();

        match deploy_contract(
            owner, recipient, name, symbol, initial_supply, initial_holders, initial_holders_amounts
        ) {
            Result::Ok(address) => {},
            Result::Err(msg) => panic(msg.panic_data),
        }
    }
    #[test]
    #[should_panic(expected: ('initial recipient mismatch',))]
    fn test_initial_recipient_mismatch() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            _,
            initial_holders_amounts
        ) =
            instantiate_params();
        let initial_holders = array![initial_holder_1, recipient, initial_holder_2,].span();

        match deploy_contract(
            owner, recipient, name, symbol, initial_supply, initial_holders, initial_holders_amounts
        ) {
            Result::Ok(address) => address.print(),
            Result::Err(msg) => panic(msg.panic_data),
        }
    }
    #[test]
    fn test_initial_recipient_ok() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();

        match deploy_contract(
            owner, recipient, name, symbol, initial_supply, initial_holders, initial_holders_amounts
        ) {
            Result::Ok(address) => {},
            Result::Err(msg) => panic(msg.panic_data),
        }
    }
    #[test]
    #[should_panic(expected: ('Unruggable: max team allocation',))]
    fn test_max_team_allocation_fail() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            _
        ) =
            instantiate_params();
        // team should have less than 100 tokens
        let initial_holders_amounts = array![900.into(), 100.into(), 50.into(),].span();
        match deploy_contract(
            owner, recipient, name, symbol, initial_supply, initial_holders, initial_holders_amounts
        ) {
            Result::Ok(address) => address.print(),
            Result::Err(msg) => panic(msg.panic_data),
        }
    }
    #[test]
    fn test_max_team_allocation_ok() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            _
        ) =
            instantiate_params();
        // team should have less than 100 tokens
        let initial_holders_amounts = array![900.into(), 50.into(), 50.into(),].span();
        match deploy_contract(
            owner, recipient, name, symbol, initial_supply, initial_holders, initial_holders_amounts
        ) {
            Result::Ok(address) => {},
            Result::Err(msg) => panic(msg.panic_data),
        }
    }
    #[test]
    fn test_max_team_allocation_ok2() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            _
        ) =
            instantiate_params();
        // team should have less than 100 tokens
        let initial_holders_amounts = array![900.into(), 50.into(), 40.into(),].span();
        match deploy_contract(
            owner, recipient, name, symbol, initial_supply, initial_holders, initial_holders_amounts
        ) {
            Result::Ok(address) => {},
            Result::Err(msg) => panic(msg.panic_data),
        }
    }
    #[test]
    #[should_panic(expected: ('Unruggable: max supply reached',))]
    fn test_max_supply_reached_fail() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            _
        ) =
            instantiate_params();
        // team should have less than 100 tokens
        let initial_holders_amounts = array![910.into(), 50.into(), 50.into(),].span();
        match deploy_contract(
            owner, recipient, name, symbol, initial_supply, initial_holders, initial_holders_amounts
        ) {
            Result::Ok(address) => address.print(),
            Result::Err(msg) => panic(msg.panic_data),
        }
    }
    #[test]
    fn test_max_supply_reached_ok() {
        let (
            owner,
            recipient,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            _
        ) =
            instantiate_params();
        // team should have less than 100 tokens
        let initial_holders_amounts = array![900.into(), 50.into(), 50.into(),].span();
        match deploy_contract(
            owner, recipient, name, symbol, initial_supply, initial_holders, initial_holders_amounts
        ) {
            Result::Ok(address) => {},
            Result::Err(msg) => panic(msg.panic_data),
        }
    }
}

mod memecoin_internals {
    use UnruggableMemecoin::{
        UnruggableMemecoinInternalImpl, SnakeEntrypoints, UnruggableEntrypoints,
        MAX_HOLDERS_BEFORE_LAUNCH
    };
    use core::debug::PrintTrait;
    use openzeppelin::token::erc20::interface::IERC20;
    use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
    use starknet::{ContractAddress, contract_address_const};
    use super::{deploy_contract, instantiate_params};
    use unruggable::tokens::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };
    use unruggable::tokens::memecoin::UnruggableMemecoin;

    #[test]
    fn test__transfer_recipients_equal_holder_cap() {
        let (
            owner, recipient, name, symbol, initial_supply, initial_holder_1, initial_holder_2, _, _
        ) =
            instantiate_params();
        let initial_holders = array![owner, initial_holder_1, initial_holder_2].span();
        let initial_holders_amounts = array![900.into(), 50.into(), 30.into(),].span();

        let contract_address =
            match deploy_contract(
                owner, owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        let mut index = 0;
        loop {
            // MAX_HOLDERS_BEFORE_LAUNCH - 3 because there are 3 initial holders
            if index == MAX_HOLDERS_BEFORE_LAUNCH - 3 {
                break;
            }

            // Transfer 1 token to the unique recipient
            // create a unique address
            let unique_recipient: ContractAddress = (index.into() + 9999).try_into().unwrap();
            start_prank(CheatTarget::One(memecoin.contract_address), owner);
            memecoin.transfer(unique_recipient, 1.into());

            // Check recipient balance. Should be equal to 1.
            let recipient_balance = memecoin.balanceOf(unique_recipient);
            assert(recipient_balance == 1.into(), 'Invalid balance recipient');

            index += 1;
        };
    }
    #[test]
    fn test__transfer_existing_holders() {
        /// pre launch holder number should not change when
        /// transfer is done to recipient(s) who already have tokens

        /// to test this, we are going to continously self transfer tokens
        /// and ensure that we can transfer more than `MAX_HOLDERS_BEFORE_LAUNCH` times

        let (
            owner, recipient, name, symbol, initial_supply, initial_holder_1, initial_holder_2, _, _
        ) =
            instantiate_params();
        let initial_holders = array![owner, initial_holder_1, initial_holder_2].span();
        let initial_holders_amounts = array![900.into(), 50.into(), 30.into(),].span();

        let contract_address =
            match deploy_contract(
                owner, owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        let mut index = 0;
        loop {
            if index == MAX_HOLDERS_BEFORE_LAUNCH - 3 {
                break;
            }

            // Self transfer tokens

            start_prank(CheatTarget::One(memecoin.contract_address), owner);
            memecoin.transfer(initial_holder_2, 1.into());

            index += 1;
        };
    }
    #[test]
    #[should_panic(expected: ('Unruggable: max holders reached',))]
    fn test__transfer_above_holder_cap() {
        let (
            owner, recipient, name, symbol, initial_supply, initial_holder_1, initial_holder_2, _, _
        ) =
            instantiate_params();
        let initial_holders = array![owner, initial_holder_1, initial_holder_2].span();
        let initial_holders_amounts = array![900.into(), 50.into(), 30.into(),].span();

        let contract_address =
            match deploy_contract(
                owner, owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        let mut index = 0;
        loop {
            // There are already 3 holders, so MAX_HOLDERS_BEFORE_LAUNCH - 2 should break
            if index == MAX_HOLDERS_BEFORE_LAUNCH - 2 {
                break;
            }

            // Transfer 1 token to the unique recipient
            let unique_recipient: ContractAddress = (index.into() + 9999).try_into().unwrap();
            start_prank(CheatTarget::One(memecoin.contract_address), owner);
            memecoin.transfer(unique_recipient, 1.into());

            index += 1;
        };
    }
// #[test]
// fn test__transfer_no_holder_cap_after_launch() {
//     let (
//         owner, recipient, name, symbol, initial_supply, initial_holder_1, initial_holder_2, _, _
//     ) =
//         instantiate_params();
//     let initial_holders = array![owner, initial_holder_1, initial_holder_2].span();
//     let initial_holders_amounts = array![900.into(), 50.into(), 30.into(),].span();

//     let contract_address =
//         match deploy_contract(
//             owner, owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
//         ) {
//         Result::Ok(address) => address,
//         Result::Err(msg) => panic(msg.panic_data),
//     };

//     let memecoin = IUnruggableMemecoinDispatcher { contract_address };

//     // set owner as caller to bypass owner restrictions
//     start_prank(CheatTarget::All, owner);

//     // launch memecoin
//     memecoin.launch_memecoin();

//     let mut index = 0;
//     loop {
//         if index == MAX_HOLDERS_BEFORE_LAUNCH {
//             break;
//         }

//         // Transfer 1 token to the unique recipient
//         let unique_recipient: ContractAddress = (index.into() + 9999).try_into().unwrap();
//         memecoin.transfer(unique_recipient, 1.into());

//         index += 1;
//     };
// }
}
