
;; title: create-event
;; version:
;; summary:
;; description:

(define-constant EXPIRATION u432)

(define-public (create-event (title (string-ascii 50)) (niche (string-ascii 30)) (desc (string-ascii 500)) (id uint) (proposer principal) (expiration uint))
   (begin
      (print { title: title, niche: niche, desc: desc, id: id, proposer: tx-sender, expiration: (+ block-height EXPIRATION) })
      (ok true)
   )
)
