
;; title: like-events
;; version:
;; summary:
;; description:

(define-public (events-like (total-votes uint) (votes-in-support uint) (proposal-id uint))
   (begin
      (print { total-votes: (+ u1 total-votes), votes-in-support: (+ u1 votes-in-support), id: proposal-id })
      (ok true)
   )
)
