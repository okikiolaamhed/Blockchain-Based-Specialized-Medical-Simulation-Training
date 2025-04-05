;; Instructor Certification Contract
;; Validates qualifications to conduct training

;; Define data maps
(define-map instructors
  { instructor-id: principal }
  {
    name: (string-ascii 100),
    specialization: (string-ascii 100),
    certification-date: uint,
    expiration-date: uint,
    certification-level: uint,
    active: bool,
    certifications: (list 10 (string-ascii 100))
  }
)

;; Define certification authority
(define-data-var certification-authority principal tx-sender)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_EXISTS u2)
(define-constant ERR_NOT_FOUND u3)
(define-constant ERR_EXPIRED u4)

;; Set certification authority
(define-public (set-certification-authority (new-authority principal))
  (begin
    (asserts! (is-eq tx-sender (var-get certification-authority)) (err ERR_UNAUTHORIZED))
    (var-set certification-authority new-authority)
    (ok true)
  )
)

;; Register a new instructor
(define-public (register-instructor
    (instructor principal)
    (name (string-ascii 100))
    (specialization (string-ascii 100))
    (certification-level uint)
    (valid-for-days uint)
    (certifications (list 10 (string-ascii 100)))
  )
  (let ((current-time (get-block-info? time (- block-height u1))))
    ;; Only certification authority can register instructors
    (asserts! (is-eq tx-sender (var-get certification-authority)) (err ERR_UNAUTHORIZED))

    ;; Check if instructor already exists
    (asserts! (is-none (map-get? instructors { instructor-id: instructor })) (err ERR_ALREADY_EXISTS))

    ;; Calculate expiration date
    (let ((cert-time (default-to u0 current-time))
          (exp-time (+ (default-to u0 current-time) (* valid-for-days u86400))))

      ;; Store instructor details
      (map-set instructors
        { instructor-id: instructor }
        {
          name: name,
          specialization: specialization,
          certification-date: cert-time,
          expiration-date: exp-time,
          certification-level: certification-level,
          active: true,
          certifications: certifications
        }
      )

      (ok instructor)
    )
  )
)

;; Renew instructor certification
(define-public (renew-certification (instructor principal) (valid-for-days uint))
  (let ((current-time (get-block-info? time (- block-height u1)))
        (instructor-data (map-get? instructors { instructor-id: instructor })))

    ;; Only certification authority can renew certifications
    (asserts! (is-eq tx-sender (var-get certification-authority)) (err ERR_UNAUTHORIZED))

    ;; Check if instructor exists
    (asserts! (is-some instructor-data) (err ERR_NOT_FOUND))

    ;; Calculate new expiration date
    (let ((new-exp-time (+ (default-to u0 current-time) (* valid-for-days u86400))))

      ;; Update expiration date
      (map-set instructors
        { instructor-id: instructor }
        (merge (unwrap-panic instructor-data)
          {
            expiration-date: new-exp-time,
            active: true
          }
        )
      )

      (ok true)
    )
  )
)

;; Deactivate instructor
(define-public (deactivate-instructor (instructor principal))
  (let ((instructor-data (map-get? instructors { instructor-id: instructor })))

    ;; Only certification authority can deactivate instructors
    (asserts! (is-eq tx-sender (var-get certification-authority)) (err ERR_UNAUTHORIZED))

    ;; Check if instructor exists
    (asserts! (is-some instructor-data) (err ERR_NOT_FOUND))

    ;; Deactivate instructor
    (map-set instructors
      { instructor-id: instructor }
      (merge (unwrap-panic instructor-data) { active: false })
    )

    (ok true)
  )
)

;; Read-only function to get instructor details
(define-read-only (get-instructor (instructor principal))
  (map-get? instructors { instructor-id: instructor })
)

;; Read-only function to check if instructor is certified and active
(define-read-only (is-certified (instructor principal))
  (let ((instructor-data (map-get? instructors { instructor-id: instructor }))
        (current-time (get-block-info? time (- block-height u1))))
    (if (is-some instructor-data)
      (let ((data (unwrap-panic instructor-data)))
        (and
          (get active data)
          (> (get expiration-date data) (default-to u0 current-time))
        )
      )
      false
    )
  )
)

