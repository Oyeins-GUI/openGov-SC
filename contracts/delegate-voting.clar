
;; title: delegate-voting
;; version: 0.0.1
;; summary:
;; description:

(define-constant POOL 'STGG2HBP7Z4ES263PSG1BN9ZF581VN9NSRNWQF1J)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_ID_DOES_NOT_EXIST (err u400))
(define-constant ERR_INSUFFICIENT_POOL_FUND (err u401))
(define-constant ERR_ALREADY_CHECKED (err u402))
(define-constant ERR_ALREADY_REACTED (err u403))

(define-data-var board-admin principal tx-sender)
(define-data-var proposals-id uint u0)

(define-map Proposals { proposal-id: uint } { 
      title: (string-ascii 50),
      goal: (string-ascii 300),
      desc: (string-ascii 500),
      needed-fund: uint,
      delegated-fund: uint,
      likes: uint,
      dislikes: uint,
      proposer: principal
   }
)
(define-map proposal-token uint { amount: uint })
(define-map delegators principal { amount: uint })
(define-map users-proposals principal uint)
(define-map checked-out uint bool)
(define-map reacted {user: principal, id: uint} bool)

(define-public  (create-proposal (title (string-ascii 50)) (goal (string-ascii 300)) (desc (string-ascii 500)) (needed-fund uint))
   (let 
      (
         (proposal-id (var-get proposals-id))
         (id (+ u1 proposal-id))
      )
      ;; #[filter(title, needed-fund, goal, desc)]
      (map-set Proposals { proposal-id: id } { 
            title: title, 
            goal: goal,
            desc: desc,
            needed-fund: needed-fund,
            delegated-fund: u0,
            likes: u0,
            dislikes: u0,
            proposer: tx-sender
      })
      (map-set proposal-token id { amount: u0 })
      (var-set proposals-id id)
      (ok id)
   )
)

(define-public (delegate-to-proposal (proposal-id uint) (amount uint))
   (let
      (
         (proposal (unwrap! (map-get? Proposals { proposal-id: proposal-id }) ERR_ID_DOES_NOT_EXIST))
         (delegated-fund (get delegated-fund (unwrap! (map-get? Proposals { proposal-id: proposal-id }) ERR_ID_DOES_NOT_EXIST)))
         (updated-proposal (merge proposal { delegated-fund: (+ delegated-fund amount) }))
      )
      ;; #[filter(amount, proposal-id)]
      (if (is-none (map-get? delegators tx-sender)) 
         (map-set delegators tx-sender { amount: amount })
         (map-set delegators tx-sender { amount: (+ (get amount (unwrap-panic (map-get? delegators tx-sender))) amount) })
      )
      (map-set Proposals { proposal-id: proposal-id} updated-proposal)
      (try! (stx-transfer? amount tx-sender .delegate-voting))
      (ok true)
   )
)

(define-public (check-out (proposal-id uint))
   (let
      (
         (proposal (unwrap! (map-get? Proposals { proposal-id: proposal-id }) ERR_ID_DOES_NOT_EXIST))
         (needed-fund (get needed-fund proposal))
         (delegated-fund (get delegated-fund proposal))
         (proposer (get proposer proposal))
         (withdrawn (map-get? checked-out proposal-id))
      )
      (asserts! (is-eq tx-sender proposer) ERR_UNAUTHORIZED)
      (asserts! (<= needed-fund (get-pool-balance)) ERR_INSUFFICIENT_POOL_FUND)
      (asserts! (is-none withdrawn) ERR_ALREADY_CHECKED)
      (try! (as-contract (stx-transfer? needed-fund .delegate-voting proposer)))
      (ok (map-set checked-out proposal-id true))
   )
)

(define-public (like-proposal (proposal-id uint))
   (let
      (
         (proposal (unwrap! (map-get? Proposals { proposal-id: proposal-id }) ERR_ID_DOES_NOT_EXIST))
         (likes (get likes (unwrap! (map-get? Proposals { proposal-id: proposal-id }) ERR_ID_DOES_NOT_EXIST)))
         (updated-proposal (merge proposal { likes: (+ likes u1) }))
      )
      ;; #[filter(proposal-id)]
      (asserts! (is-none (map-get? reacted {user: tx-sender, id: proposal-id})) ERR_ALREADY_REACTED)
      (map-set Proposals { proposal-id: proposal-id } updated-proposal)
      (map-set reacted {user: tx-sender, id: proposal-id} true)
      (ok true)
   )
)

(define-public (dislike-proposal (proposal-id uint))
   (let
      (
         (proposal (unwrap! (map-get? Proposals { proposal-id: proposal-id }) ERR_ID_DOES_NOT_EXIST))
         (dislikes (get dislikes (unwrap! (map-get? Proposals { proposal-id: proposal-id }) ERR_ID_DOES_NOT_EXIST)))
         (updated-proposal (merge proposal { dislikes: (+ dislikes u1) }))
      )
      ;; #[filter(proposal-id)]
      (asserts! (is-none (map-get? reacted {user: tx-sender, id: proposal-id})) ERR_ALREADY_REACTED)
      (map-set Proposals { proposal-id: proposal-id } updated-proposal)
      (map-set reacted {user: tx-sender, id: proposal-id} true)
      (ok true)
   )
)

(define-public (delegate-to-pool (amount uint))
   (stx-transfer? amount tx-sender .delegate-voting)
)

(define-read-only (get-delegated-tokens)
   (map-get? delegators tx-sender)
)

(define-read-only (check-proposal (proposal-id uint))
   (ok (unwrap! (map-get? Proposals { proposal-id: proposal-id }) ERR_ID_DOES_NOT_EXIST))
)

(define-read-only (get-pool-balance)
   (stx-get-balance .delegate-voting)
)
