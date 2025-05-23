;; Institution Verification Contract
;; Validates and stores information about financial entities

(define-data-var admin principal tx-sender)

;; Map to store verified institutions
(define-map verified-institutions
  { institution-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    verification-status: bool,
    verification-date: uint,
    risk-level: uint,
    last-updated: uint
  }
)

;; Public function to register a new institution
(define-public (register-institution (institution-id (string-ascii 64)) (name (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? verified-institutions { institution-id: institution-id })) (err u100))
    (ok (map-insert verified-institutions
      { institution-id: institution-id }
      {
        name: name,
        verification-status: false,
        verification-date: u0,
        risk-level: u5,
        last-updated: block-height
      }
    ))
  )
)

;; Public function to verify an institution
(define-public (verify-institution (institution-id (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? verified-institutions { institution-id: institution-id })) (err u404))
    (ok (map-set verified-institutions
      { institution-id: institution-id }
      (merge (unwrap-panic (map-get? verified-institutions { institution-id: institution-id }))
        {
          verification-status: true,
          verification-date: block-height,
          last-updated: block-height
        }
      )
    ))
  )
)

;; Public function to update institution risk level
(define-public (update-risk-level (institution-id (string-ascii 64)) (risk-level uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? verified-institutions { institution-id: institution-id })) (err u404))
    (asserts! (<= risk-level u10) (err u400))
    (ok (map-set verified-institutions
      { institution-id: institution-id }
      (merge (unwrap-panic (map-get? verified-institutions { institution-id: institution-id }))
        {
          risk-level: risk-level,
          last-updated: block-height
        }
      )
    ))
  )
)

;; Read-only function to check if an institution is verified
(define-read-only (is-institution-verified (institution-id (string-ascii 64)))
  (match (map-get? verified-institutions { institution-id: institution-id })
    institution (get verification-status institution)
    false
  )
)

;; Read-only function to get institution details
(define-read-only (get-institution-details (institution-id (string-ascii 64)))
  (map-get? verified-institutions { institution-id: institution-id })
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
