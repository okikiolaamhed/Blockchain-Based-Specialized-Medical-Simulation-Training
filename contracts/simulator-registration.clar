;; Simulator Registration Contract
;; Records details of medical training equipment

;; Define data maps
(define-map simulators
  { simulator-id: (string-ascii 36) }
  {
    name: (string-ascii 100),
    model: (string-ascii 100),
    manufacturer: (string-ascii 100),
    purchase-date: uint,
    last-maintenance: uint,
    status: (string-ascii 20),
    features: (list 10 (string-ascii 100))
  }
)

(define-map simulator-owners
  { simulator-id: (string-ascii 36) }
  { owner: principal }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_EXISTS u2)
(define-constant ERR_NOT_FOUND u3)

;; Register a new simulator
(define-public (register-simulator
    (simulator-id (string-ascii 36))
    (name (string-ascii 100))
    (model (string-ascii 100))
    (manufacturer (string-ascii 100))
    (purchase-date uint)
    (features (list 10 (string-ascii 100)))
  )
  (let ((current-time (get-block-info? time (- block-height u1))))
    (asserts! (is-none (map-get? simulators { simulator-id: simulator-id })) (err ERR_ALREADY_EXISTS))

    ;; Store simulator details
    (map-set simulators
      { simulator-id: simulator-id }
      {
        name: name,
        model: model,
        manufacturer: manufacturer,
        purchase-date: purchase-date,
        last-maintenance: (default-to u0 current-time),
        status: "active",
        features: features
      }
    )

    ;; Set ownership
    (map-set simulator-owners
      { simulator-id: simulator-id }
      { owner: tx-sender }
    )

    (ok simulator-id)
  )
)

;; Update simulator maintenance record
(define-public (update-maintenance (simulator-id (string-ascii 36)))
  (let ((current-time (get-block-info? time (- block-height u1)))
        (simulator-data (map-get? simulators { simulator-id: simulator-id }))
        (owner-data (map-get? simulator-owners { simulator-id: simulator-id })))

    ;; Check if simulator exists
    (asserts! (is-some simulator-data) (err ERR_NOT_FOUND))

    ;; Check if sender is the owner
    (asserts! (is-eq (some { owner: tx-sender }) owner-data) (err ERR_UNAUTHORIZED))

    ;; Update maintenance timestamp
    (map-set simulators
      { simulator-id: simulator-id }
      (merge (unwrap-panic simulator-data) { last-maintenance: (default-to u0 current-time) })
    )

    (ok true)
  )
)

;; Update simulator status
(define-public (update-status (simulator-id (string-ascii 36)) (new-status (string-ascii 20)))
  (let ((simulator-data (map-get? simulators { simulator-id: simulator-id }))
        (owner-data (map-get? simulator-owners { simulator-id: simulator-id })))

    ;; Check if simulator exists
    (asserts! (is-some simulator-data) (err ERR_NOT_FOUND))

    ;; Check if sender is the owner
    (asserts! (is-eq (some { owner: tx-sender }) owner-data) (err ERR_UNAUTHORIZED))

    ;; Update status
    (map-set simulators
      { simulator-id: simulator-id }
      (merge (unwrap-panic simulator-data) { status: new-status })
    )

    (ok true)
  )
)

;; Read-only function to get simulator details
(define-read-only (get-simulator (simulator-id (string-ascii 36)))
  (map-get? simulators { simulator-id: simulator-id })
)

;; Read-only function to get simulator owner
(define-read-only (get-simulator-owner (simulator-id (string-ascii 36)))
  (map-get? simulator-owners { simulator-id: simulator-id })
)

