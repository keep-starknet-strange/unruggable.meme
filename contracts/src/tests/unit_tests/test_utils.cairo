use unruggable::utils::unique_count;
#[test]
fn test_unique_count() {
    let elems: Array<u128> = array![1, 2, 2, 3, 4, 4, 5, 6];
    let count = unique_count(elems.span());
    assert_eq!(count, 6)
}
