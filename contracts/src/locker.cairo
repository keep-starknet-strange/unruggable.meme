mod interface;
mod token_locker;
mod errors;

use token_locker::{TokenLocker, TokenLocker::TokenLock};
use interface::{ITokenLocker, ITokenLockerDispatcher, ITokenLockerDispatcherTrait};
