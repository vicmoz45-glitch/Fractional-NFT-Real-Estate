(impl-trait .sip009-nft-trait.sip009-nft-trait)  

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-token-exists (err u102))
(define-constant err-token-not-found (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-property-not-found (err u105))
(define-constant err-insufficient-shares (err u106))
(define-constant err-transfer-not-allowed (err u107))
(define-constant err-nothing-to-claim (err u108))
(define-constant err-listing-not-found (err u109))
(define-constant err-price-zero (err u110))
(define-constant err-cannot-buy-own-token (err u111))
(define-constant err-seller-not-owner (err u112))

(define-non-fungible-token fractional-share uint)

(define-data-var last-token-id uint u0)
(define-data-var last-property-id uint u0)

(define-map properties
    uint
    {
        name: (string-ascii 64),
        total-shares: uint,
        shares-minted: uint,
        dividend-per-share: uint,
        total-dividends: uint
    }
)

(define-map token-property
    uint
    uint
)

(define-map share-dividend-claimed
    uint
    uint
)

(define-map token-uri-map
    uint
    (string-ascii 256)
)

(define-map market-listings
    uint
    {
        price: uint,
        seller: principal
    }
)

(define-public (create-property (name (string-ascii 64)) (total-shares uint))
    (let
        (
            (property-id (+ (var-get last-property-id) u1))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> total-shares u0) err-invalid-amount)
        (map-set properties property-id {
            name: name,
            total-shares: total-shares,
            shares-minted: u0,
            dividend-per-share: u0,
            total-dividends: u0
        })
        (var-set last-property-id property-id)
        (ok property-id)
    )
)

(define-public (mint-share (property-id uint) (recipient principal))
    (let
        (
            (property (unwrap! (map-get? properties property-id) err-property-not-found))
            (current-minted (get shares-minted property))
            (total-shares (get total-shares property))
            (token-id (+ (var-get last-token-id) u1))
            (current-dividend-per-share (get dividend-per-share property))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (< current-minted total-shares) err-insufficient-shares)
        
        (try! (nft-mint? fractional-share token-id recipient))
        
        (map-set token-property token-id property-id)
        (map-set share-dividend-claimed token-id current-dividend-per-share)
        
        (map-set properties property-id (merge property {
            shares-minted: (+ current-minted u1)
        }))
        
        (var-set last-token-id token-id)
        (ok token-id)
    )
)

(define-public (deposit-dividends (property-id uint) (amount uint))
    (let
        (
            (property (unwrap! (map-get? properties property-id) err-property-not-found))
            (total-shares (get total-shares property))
            (current-dividend-per-share (get dividend-per-share property))
            (current-total-dividends (get total-dividends property))
            (divider-increase (/ amount total-shares))
        )
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (> total-shares u0) err-invalid-amount)
        
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        (map-set properties property-id (merge property {
            dividend-per-share: (+ current-dividend-per-share divider-increase),
            total-dividends: (+ current-total-dividends amount)
        }))
        (ok true)
    )
)

(define-public (claim-dividends (token-id uint))
    (let
        (
            (property-id (unwrap! (map-get? token-property token-id) err-token-not-found))
            (property (unwrap! (map-get? properties property-id) err-property-not-found))
            (owner (unwrap! (nft-get-owner? fractional-share token-id) err-token-not-found))
            (current-dividend-per-share (get dividend-per-share property))
            (last-claimed-amount (default-to u0 (map-get? share-dividend-claimed token-id)))
            (pending-utils (- current-dividend-per-share last-claimed-amount))
        )
        (asserts! (is-eq tx-sender owner) err-not-token-owner)
        (asserts! (> pending-utils u0) err-nothing-to-claim)
        
        (try! (as-contract (stx-transfer? pending-utils tx-sender owner)))
        
        (map-set share-dividend-claimed token-id current-dividend-per-share)
        (ok pending-utils)
    )
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender sender) err-not-token-owner)
        (nft-transfer? fractional-share token-id sender recipient)
    )
)

(define-read-only (get-last-token-id)
    (ok (var-get last-token-id))
)

(define-read-only (get-token-uri (token-id uint))
    (ok (map-get? token-uri-map token-id))
)

(define-read-only (get-owner (token-id uint))
    (ok (nft-get-owner? fractional-share token-id))
)

(define-public (set-token-uri (token-id uint) (new-uri (string-ascii 256)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-some (nft-get-owner? fractional-share token-id)) err-token-not-found)
        (map-set token-uri-map token-id new-uri)
        (ok true)
    )
)

(define-read-only (get-property-details (property-id uint))
    (map-get? properties property-id)
)

(define-read-only (get-share-property (token-id uint))
    (map-get? token-property token-id)
)

(define-read-only (get-pending-dividends (token-id uint))
    (let
        (
            (property-id (unwrap! (map-get? token-property token-id) (ok u0)))
            (property (unwrap! (map-get? properties property-id) (ok u0)))
            (current-dividend-per-share (get dividend-per-share property))
            (last-claimed-amount (default-to u0 (map-get? share-dividend-claimed token-id)))
        )
        (if (is-eq property-id u0)
            (ok u0)
            (ok (- current-dividend-per-share last-claimed-amount))
        )
    )
)

(define-read-only (get-contract-balance)
    (stx-get-balance (as-contract tx-sender))
)

(define-read-only (get-listing (token-id uint))
    (map-get? market-listings token-id)
)

(define-public (list-in-marketplace (token-id uint) (price uint))
    (let
        (
            (owner (unwrap! (nft-get-owner? fractional-share token-id) err-token-not-found))
        )
        (asserts! (is-eq tx-sender owner) err-not-token-owner)
        (asserts! (> price u0) err-price-zero)
        (try! (nft-transfer? fractional-share token-id tx-sender (as-contract tx-sender)))
        (map-set market-listings token-id {
            price: price,
            seller: tx-sender
        })
        (ok true)
    )
)

(define-public (unlist-in-marketplace (token-id uint))
    (let
        (
            (listing (unwrap! (map-get? market-listings token-id) err-listing-not-found))
            (seller (get seller listing))
        )
        (asserts! (is-eq tx-sender seller) err-not-token-owner)
        (try! (as-contract (nft-transfer? fractional-share token-id tx-sender seller)))
        (map-delete market-listings token-id)
        (ok true)
    )
)

(define-public (buy-from-marketplace (token-id uint))
    (let
        (
            (listing (unwrap! (map-get? market-listings token-id) err-listing-not-found))
            (price (get price listing))
            (seller (get seller listing))
            (owner (unwrap! (nft-get-owner? fractional-share token-id) err-token-not-found))
            (buyer tx-sender)
        )
        (asserts! (not (is-eq buyer seller)) err-cannot-buy-own-token)
        (asserts! (is-eq owner (as-contract tx-sender)) err-token-not-found)
        (try! (stx-transfer? price buyer seller))
        (try! (as-contract (nft-transfer? fractional-share token-id tx-sender buyer)))
        (map-delete market-listings token-id)
        (ok true)
    )
)
