mod errors;
mod interface;
mod token_locker;
use interface::{ITokenLocker, ITokenLockerDispatcher, ITokenLockerDispatcherTrait};

use token_locker::{TokenLocker, TokenLocker::TokenLock};
