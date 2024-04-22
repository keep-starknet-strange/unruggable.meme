mod errors;
mod interface;
mod lock_manager;
mod lock_position;
use interface::{ILockManager, ILockManagerDispatcher, ILockManagerDispatcherTrait};

use lock_manager::{LockManager, LockManager::TokenLock, LockManager::LockPosition};
