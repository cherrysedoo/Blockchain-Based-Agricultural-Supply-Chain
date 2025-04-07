;; Logistics Tracking Contract
;; This contract monitors movement from farm to processor

(define-data-var admin principal tx-sender)

;; Shipment status: 1 = Created, 2 = In Transit, 3 = Delivered, 4 = Rejected
(define-map shipments
  { shipment-id: (string-utf8 36) }
  {
    farm-id: (string-utf8 36),
    crop-type: (string-utf8 50),
    quantity: uint,
    origin: (string-utf8 100),
    destination: (string-utf8 100),
    status: uint,
    creation-date: uint,
    last-updated: uint
  }
)

;; Track shipment status changes
(define-map shipment-history
  { shipment-id: (string-utf8 36), timestamp: uint }
  {
    status: uint,
    location: (string-utf8 100),
    updated-by: principal
  }
)

;; Create a new shipment
(define-public (create-shipment
                (shipment-id (string-utf8 36))
                (farm-id (string-utf8 36))
                (crop-type (string-utf8 50))
                (quantity uint)
                (origin (string-utf8 100))
                (destination (string-utf8 100)))
  (let ((caller tx-sender))
    (asserts! (is-none (map-get? shipments { shipment-id: shipment-id })) (err u1)) ;; Shipment ID already exists

    ;; Create the shipment
    (map-set shipments
      { shipment-id: shipment-id }
      {
        farm-id: farm-id,
        crop-type: crop-type,
        quantity: quantity,
        origin: origin,
        destination: destination,
        status: u1, ;; Created
        creation-date: block-height,
        last-updated: block-height
      }
    )

    ;; Record initial status in history
    (map-set shipment-history
      { shipment-id: shipment-id, timestamp: block-height }
      {
        status: u1,
        location: origin,
        updated-by: caller
      }
    )

    (ok true)
  )
)

;; Update shipment status
(define-public (update-shipment-status
                (shipment-id (string-utf8 36))
                (new-status uint)
                (current-location (string-utf8 100)))
  (let ((caller tx-sender))
    (match (map-get? shipments { shipment-id: shipment-id })
      shipment-data
        (begin
          ;; Update the shipment
          (map-set shipments
            { shipment-id: shipment-id }
            (merge shipment-data
              {
                status: new-status,
                last-updated: block-height
              }
            )
          )

          ;; Record in history
          (map-set shipment-history
            { shipment-id: shipment-id, timestamp: block-height }
            {
              status: new-status,
              location: current-location,
              updated-by: caller
            }
          )

          (ok true)
        )
      (err u404) ;; Shipment not found
    )
  )
)

;; Get shipment details
(define-read-only (get-shipment-details (shipment-id (string-utf8 36)))
  (map-get? shipments { shipment-id: shipment-id })
)

;; Get shipment status at a specific time
(define-read-only (get-shipment-history (shipment-id (string-utf8 36)) (timestamp uint))
  (map-get? shipment-history { shipment-id: shipment-id, timestamp: timestamp })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (let ((caller tx-sender))
    (asserts! (is-eq caller (var-get admin)) (err u403)) ;; Not authorized
    (ok (var-set admin new-admin))
  )
)

