;; Scenario Management Contract
;; Tracks specific clinical situations practiced

;; Define data maps
(define-map scenarios
  { scenario-id: (string-ascii 36) }
  {
    name: (string-ascii 100),
    description: (string-utf8 500),
    difficulty: uint,
    specialties: (list 5 (string-ascii 50)),
    created-by: principal,
    created-at: uint,
    updated-at: uint,
    active: bool
  }
)

(define-map scenario-sessions
  { session-id: (string-ascii 36) }
  {
    scenario-id: (string-ascii 36),
    instructor: principal,
    start-time: uint,
    end-time: uint,
    participants: (list 20 principal),
    completed: bool
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_EXISTS u2)
(define-constant ERR_NOT_FOUND u3)
(define-constant ERR_INVALID_INSTRUCTOR u4)
(define-constant ERR_SESSION_COMPLETED u5)

;; Create a new scenario
(define-public (create-scenario
    (scenario-id (string-ascii 36))
    (name (string-ascii 100))
    (description (string-utf8 500))
    (difficulty uint)
    (specialties (list 5 (string-ascii 50)))
  )
  (let ((current-time (get-block-info? time (- block-height u1))))
    ;; Check if scenario already exists
    (asserts! (is-none (map-get? scenarios { scenario-id: scenario-id })) (err ERR_ALREADY_EXISTS))

    ;; Store scenario details
    (map-set scenarios
      { scenario-id: scenario-id }
      {
        name: name,
        description: description,
        difficulty: difficulty,
        specialties: specialties,
        created-by: tx-sender,
        created-at: (default-to u0 current-time),
        updated-at: (default-to u0 current-time),
        active: true
      }
    )

    (ok scenario-id)
  )
)

;; Update an existing scenario
(define-public (update-scenario
    (scenario-id (string-ascii 36))
    (name (string-ascii 100))
    (description (string-utf8 500))
    (difficulty uint)
    (specialties (list 5 (string-ascii 50)))
  )
  (let ((current-time (get-block-info? time (- block-height u1)))
        (scenario-data (map-get? scenarios { scenario-id: scenario-id })))

    ;; Check if scenario exists
    (asserts! (is-some scenario-data) (err ERR_NOT_FOUND))

    ;; Check if sender is the creator
    (asserts! (is-eq (get created-by (unwrap-panic scenario-data)) tx-sender) (err ERR_UNAUTHORIZED))

    ;; Update scenario details
    (map-set scenarios
      { scenario-id: scenario-id }
      {
        name: name,
        description: description,
        difficulty: difficulty,
        specialties: specialties,
        created-by: tx-sender,
        created-at: (get created-at (unwrap-panic scenario-data)),
        updated-at: (default-to u0 current-time),
        active: true
      }
    )

    (ok true)
  )
)

;; Start a new training session
(define-public (start-session
    (session-id (string-ascii 36))
    (scenario-id (string-ascii 36))
    (participants (list 20 principal))
  )
  (let ((current-time (get-block-info? time (- block-height u1)))
        (scenario-data (map-get? scenarios { scenario-id: scenario-id })))

    ;; Check if scenario exists and is active
    (asserts! (and (is-some scenario-data) (get active (unwrap-panic scenario-data))) (err ERR_NOT_FOUND))

    ;; Check if session already exists
    (asserts! (is-none (map-get? scenario-sessions { session-id: session-id })) (err ERR_ALREADY_EXISTS))

    ;; Verify instructor certification (would call instructor-certification contract in a real implementation)
    ;; For simplicity, we're just checking that the instructor exists
    ;; In a real implementation, we would use contract-call? to verify certification

    ;; Store session details
    (map-set scenario-sessions
      { session-id: session-id }
      {
        scenario-id: scenario-id,
        instructor: tx-sender,
        start-time: (default-to u0 current-time),
        end-time: u0,
        participants: participants,
        completed: false
      }
    )

    (ok session-id)
  )
)

;; Complete a training session
(define-public (complete-session (session-id (string-ascii 36)))
  (let ((current-time (get-block-info? time (- block-height u1)))
        (session-data (map-get? scenario-sessions { session-id: session-id })))

    ;; Check if session exists
    (asserts! (is-some session-data) (err ERR_NOT_FOUND))

    ;; Check if sender is the instructor
    (asserts! (is-eq (get instructor (unwrap-panic session-data)) tx-sender) (err ERR_UNAUTHORIZED))

    ;; Check if session is not already completed
    (asserts! (not (get completed (unwrap-panic session-data))) (err ERR_SESSION_COMPLETED))

    ;; Update session to completed
    (map-set scenario-sessions
      { session-id: session-id }
      (merge (unwrap-panic session-data)
        {
          end-time: (default-to u0 current-time),
          completed: true
        }
      )
    )

    (ok true)
  )
)

;; Read-only function to get scenario details
(define-read-only (get-scenario (scenario-id (string-ascii 36)))
  (map-get? scenarios { scenario-id: scenario-id })
)

;; Read-only function to get session details
(define-read-only (get-session (session-id (string-ascii 36)))
  (map-get? scenario-sessions { session-id: session-id })
)

