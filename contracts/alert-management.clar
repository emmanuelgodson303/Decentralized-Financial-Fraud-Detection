;; Alert Management Contract
;; Handles notification of potential fraud

(define-data-var admin principal tx-sender)
(define-data-var alert-counter uint u0)

;; Map to store alerts
(define-map alerts
  { alert-id: uint }
  {
    tx-id: (string-ascii 64),
    risk-score: uint,
    risk-level: (string-ascii 10),
    timestamp: uint,
    status: (string-ascii 20),
    assigned-to: (optional principal),
    resolution: (optional (string-ascii 100))
  }
)

;; Map to track alerts by institution
(define-map institution-alerts
  { institution-id: (string-ascii 64) }
  { alert-ids: (list 100 uint) }
)

;; Public function to create a new alert
(define-public (create-alert
    (tx-id (string-ascii 64))
    (risk-score uint)
    (risk-level (string-ascii 10))
    (institution-id (string-ascii 64)))
  (let ((new-alert-id (+ (var-get alert-counter) u1)))
    (begin
      ;; Increment alert counter
      (var-set alert-counter new-alert-id)

      ;; Create the alert
      (map-insert alerts
        { alert-id: new-alert-id }
        {
          tx-id: tx-id,
          risk-score: risk-score,
          risk-level: risk-level,
          timestamp: block-height,
          status: "new",
          assigned-to: none,
          resolution: none
        }
      )

      ;; Add alert to institution's alert list
      (add-alert-to-institution institution-id new-alert-id)

      (ok new-alert-id)
    )
  )
)

;; Private function to add alert to institution's list
(define-private (add-alert-to-institution (institution-id (string-ascii 64)) (alert-id uint))
  (match (map-get? institution-alerts { institution-id: institution-id })
    existing-alerts
      (map-set institution-alerts
        { institution-id: institution-id }
        { alert-ids: (unwrap-panic (as-max-len? (append (get alert-ids existing-alerts) alert-id) u100)) }
      )
    (map-insert institution-alerts
      { institution-id: institution-id }
      { alert-ids: (list alert-id) }
    )
  )
)

;; Public function to assign an alert to an investigator
(define-public (assign-alert (alert-id uint) (investigator principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? alerts { alert-id: alert-id })) (err u404))
    (ok (map-set alerts
      { alert-id: alert-id }
      (merge (unwrap-panic (map-get? alerts { alert-id: alert-id }))
        {
          status: "assigned",
          assigned-to: (some investigator)
        }
      )
    ))
  )
)

;; Public function to update alert status
(define-public (update-alert-status (alert-id uint) (status (string-ascii 20)))
  (begin
    (asserts! (is-some (map-get? alerts { alert-id: alert-id })) (err u404))
    (let ((alert (unwrap-panic (map-get? alerts { alert-id: alert-id }))))
      (asserts! (or
                  (is-eq tx-sender (var-get admin))
                  (is-eq (some tx-sender) (get assigned-to alert))
                )
                (err u403))
      (ok (map-set alerts
        { alert-id: alert-id }
        (merge alert { status: status })
      ))
    )
  )
)

;; Public function to resolve an alert
(define-public (resolve-alert (alert-id uint) (resolution (string-ascii 100)))
  (begin
    (asserts! (is-some (map-get? alerts { alert-id: alert-id })) (err u404))
    (let ((alert (unwrap-panic (map-get? alerts { alert-id: alert-id }))))
      (asserts! (or
                  (is-eq tx-sender (var-get admin))
                  (is-eq (some tx-sender) (get assigned-to alert))
                )
                (err u403))
      (ok (map-set alerts
        { alert-id: alert-id }
        (merge alert
          {
            status: "resolved",
            resolution: (some resolution)
          }
        )
      ))
    )
  )
)

;; Read-only function to get alert details
(define-read-only (get-alert (alert-id uint))
  (map-get? alerts { alert-id: alert-id })
)

;; Read-only function to get all alerts for an institution
(define-read-only (get-institution-alerts (institution-id (string-ascii 64)))
  (map-get? institution-alerts { institution-id: institution-id })
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
