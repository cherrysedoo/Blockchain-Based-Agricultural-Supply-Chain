;; Farm Verification Contract
;; This contract validates legitimate agricultural producers

(define-data-var admin principal tx-sender)

;; Farm status: 0 = unverified, 1 = verified, 2 = suspended
(define-map farms
  { farm-id: (string-utf8 36) }
  {
    owner: principal,
    name: (string-utf8 100),
    location: (string-utf8 100),
    status: uint,
    registration-date: uint
  }
)

;; Register a new farm
(define-public (register-farm (farm-id (string-utf8 36)) (name (string-utf8 100)) (location (string-utf8 100)))
  (let ((caller tx-sender))
    (asserts! (is-none (map-get? farms { farm-id: farm-id })) (err u1)) ;; Farm ID already exists
    (ok (map-set farms
      { farm-id: farm-id }
      {
        owner: caller,
        name: name,
        location: location,
        status: u0, ;; Unverified by default
        registration-date: block-height
      }
    ))
  )
)

;; Verify a farm (admin only)
(define-public (verify-farm (farm-id (string-utf8 36)))
  (let ((caller tx-sender))
    (asserts! (is-eq caller (var-get admin)) (err u403)) ;; Not authorized
    (match (map-get? farms { farm-id: farm-id })
      farm-data (ok (map-set farms
                    { farm-id: farm-id }
                    (merge farm-data { status: u1 })))
      (err u404) ;; Farm not found
    )
  )
)

;; Suspend a farm (admin only)
(define-public (suspend-farm (farm-id (string-utf8 36)))
  (let ((caller tx-sender))
    (asserts! (is-eq caller (var-get admin)) (err u403)) ;; Not authorized
    (match (map-get? farms { farm-id: farm-id })
      farm-data (ok (map-set farms
                    { farm-id: farm-id }
                    (merge farm-data { status: u2 })))
      (err u404) ;; Farm not found
    )
  )
)

;; Get farm details
(define-read-only (get-farm-details (farm-id (string-utf8 36)))
  (map-get? farms { farm-id: farm-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (let ((caller tx-sender))
    (asserts! (is-eq caller (var-get admin)) (err u403)) ;; Not authorized
    (ok (var-set admin new-admin))
  )
)

