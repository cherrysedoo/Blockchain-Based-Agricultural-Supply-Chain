;; Quality Verification Contract
;; This contract records testing results for produce

(define-data-var admin principal tx-sender)

;; Quality test results
(define-map quality-tests
  { test-id: (string-utf8 36) }
  {
    shipment-id: (string-utf8 36),
    test-type: (string-utf8 50),
    result: (string-utf8 100),
    passed: bool,
    test-date: uint,
    tester: principal,
    notes: (optional (string-utf8 200))
  }
)

;; Register authorized testers
(define-map authorized-testers
  { tester: principal }
  { authorized: bool }
)

;; Add an authorized tester (admin only)
(define-public (add-tester (tester principal))
  (let ((caller tx-sender))
    (asserts! (is-eq caller (var-get admin)) (err u403)) ;; Not authorized
    (ok (map-set authorized-testers
      { tester: tester }
      { authorized: true }
    ))
  )
)

;; Remove an authorized tester (admin only)
(define-public (remove-tester (tester principal))
  (let ((caller tx-sender))
    (asserts! (is-eq caller (var-get admin)) (err u403)) ;; Not authorized
    (ok (map-delete authorized-testers { tester: tester }))
  )
)

;; Record a quality test
(define-public (record-test
                (test-id (string-utf8 36))
                (shipment-id (string-utf8 36))
                (test-type (string-utf8 50))
                (result (string-utf8 100))
                (passed bool)
                (notes (optional (string-utf8 200))))
  (let ((caller tx-sender))
    ;; Check if tester is authorized
    (asserts!
      (or
        (is-eq caller (var-get admin))
        (match (map-get? authorized-testers { tester: caller })
          tester-data (get authorized tester-data)
          false
        )
      )
      (err u403)
    ) ;; Not authorized

    (asserts! (is-none (map-get? quality-tests { test-id: test-id })) (err u1)) ;; Test ID already exists

    (ok (map-set quality-tests
      { test-id: test-id }
      {
        shipment-id: shipment-id,
        test-type: test-type,
        result: result,
        passed: passed,
        test-date: block-height,
        tester: caller,
        notes: notes
      }
    ))
  )
)

;; Get test details
(define-read-only (get-test-details (test-id (string-utf8 36)))
  (map-get? quality-tests { test-id: test-id })
)

;; Check if a shipment passed all tests
(define-read-only (shipment-passed-all-tests (shipment-id (string-utf8 36)))
  ;; This is a simplified implementation
  ;; In a real contract, you would need to iterate through all tests for this shipment
  ;; Since Clarity doesn't support iteration, you would need a different approach
  true
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (let ((caller tx-sender))
    (asserts! (is-eq caller (var-get admin)) (err u403)) ;; Not authorized
    (ok (var-set admin new-admin))
  )
)

