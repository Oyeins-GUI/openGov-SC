
;; title: fund-treasury-pool

(define-public (fund-treasury-pool (amount uint))
   (stx-transfer? amount tx-sender 'ST33Y5T5GF91HE6PGD9QD0JAC93XHT2P52TW0P3YC)
)
