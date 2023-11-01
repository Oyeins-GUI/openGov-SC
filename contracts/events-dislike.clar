
;; title: like-events
;; version:
;; summary:
;; description:

(define-public (events-dislike (total-votes uint) (votes-against uint) (proposal-id uint))
   (begin
      (print { total-votes: (+ u1 total-votes), votes-in-support: (+ u1 votes-against), id: proposal-id })
      (ok true)
   )
)
