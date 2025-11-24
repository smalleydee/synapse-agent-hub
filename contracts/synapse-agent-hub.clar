;; ------------------------------------------------------------
;; Contract: synapse-agent-hub.clar
;; Purpose:  Decentralized Autonomous Agent Trading Hub
;; Author:   smalley
;; ------------------------------------------------------------

(define-constant ERR-NOT-ADMIN (err u100))
(define-constant ERR-ALREADY-REGISTERED (err u101))
(define-constant ERR-NOT-REGISTERED (err u102))
(define-constant ERR-INSUFFICIENT-STAKE (err u103))
(define-constant ERR-INVALID-AMOUNT (err u104))
(define-constant ERR-NOT-OWNER (err u105))
(define-constant ERR-UNAUTHORIZED (err u106))

;; ------------------------------------------------------------
;; Global Variables
;; ------------------------------------------------------------

(define-data-var admin principal tx-sender)
(define-data-var min-stake uint u100000) ;; 0.1 STX minimum stake
(define-data-var trade-fee uint u500) ;; 0.0005 STX per trade
(define-data-var total-agents uint u0)

;; ------------------------------------------------------------
;; Data Maps
;; ------------------------------------------------------------

(define-map agents
  { agent-id: uint }
  {
    owner: principal,
    active: bool,
    stake: uint,
    trades: uint,
    profit: int,
    registered-at: uint
  }
)

(define-map agent-lookup
  { owner: principal }
  { agent-id: uint }
)

;; ------------------------------------------------------------
;; Events (emitted via print)
;; ------------------------------------------------------------

;; ------------------------------------------------------------
;; Helpers
;; ------------------------------------------------------------

(define-private (only-admin)
  (if (is-eq tx-sender (var-get admin))
      (ok true)
      ERR-NOT-ADMIN))

(define-private (get-agent-by-owner (who principal))
  (match (map-get? agent-lookup { owner: who }) rec
    (ok (get agent-id rec))
    ERR-NOT-REGISTERED))

;; ------------------------------------------------------------
;; ADMIN FUNCTIONS
;; ------------------------------------------------------------

(define-public (set-admin (new-admin principal))
  (begin
    (try! (only-admin))
    (asserts! (not (is-eq new-admin tx-sender)) ERR-NOT-ADMIN)
    (var-set admin new-admin)
    (print "admin-updated")
    (ok true)))

(define-public (set-min-stake (amount uint))
  (begin
    (try! (only-admin))
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (var-set min-stake amount)
    (ok true)))

(define-public (set-trade-fee (fee uint))
  (begin
    (try! (only-admin))
    (asserts! (>= fee u0) ERR-INVALID-AMOUNT)
    (var-set trade-fee fee)
    (ok true)))

;; ------------------------------------------------------------
;; AGENT MANAGEMENT
;; ------------------------------------------------------------

(define-public (register-agent)
  (if (is-some (map-get? agent-lookup { owner: tx-sender }))
      ERR-ALREADY-REGISTERED
      (let ((stake (var-get min-stake))
            (agent-id (+ u1 (var-get total-agents))))
        (begin
          (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))
          (map-set agents { agent-id: agent-id }
            {
              owner: tx-sender,
              active: true,
              stake: stake,
              trades: u0,
              profit: 0,
              registered-at: burn-block-height
            })
          (map-set agent-lookup { owner: tx-sender } { agent-id: agent-id })
          (var-set total-agents agent-id)
          (print "agent-registered")
          (ok agent-id)))))

(define-public (deactivate-agent (agent-id uint))
  (let ((agent (map-get? agents { agent-id: agent-id })))
    (match agent
      a
      (if (is-eq tx-sender (get owner a))
          (begin
            (map-set agents { agent-id: agent-id } (merge a { active: false }))
            (try! (stx-transfer? (get stake a) (as-contract tx-sender) tx-sender))
            (print "agent-deactivated")
            (ok true))
          ERR-NOT-OWNER)
      ERR-NOT-REGISTERED)))

;; ------------------------------------------------------------
;; TRADING LOGIC
;; ------------------------------------------------------------

(define-public (execute-trade (agent-id uint) (side (string-ascii 4)) (amount uint) (profit int))
  (let ((agent (map-get? agents { agent-id: agent-id })))
    (match agent
      a
      (if (and (get active a) (is-eq (get owner a) tx-sender))
          (begin
            ;; apply fee
            (try! (stx-transfer? (var-get trade-fee) tx-sender (as-contract tx-sender)))

            ;; update agent performance
            (let ((new-profit (+ (get profit a) profit))
                  (new-trades (+ (get trades a) u1)))
              (map-set agents { agent-id: agent-id }
                (merge a { profit: new-profit, trades: new-trades }))
              (print "trade-executed")
              (ok true)))
          ERR-UNAUTHORIZED)
      ERR-NOT-REGISTERED)))

(define-public (slash-stake (agent-id uint) (amount uint))
  (begin
    (try! (only-admin))
    (asserts! (> agent-id u0) ERR-NOT-REGISTERED)
    (let ((agent (map-get? agents { agent-id: agent-id })))
      (match agent
        a
        (if (>= (get stake a) amount)
            (begin
              (map-set agents { agent-id: agent-id }
                (merge a { stake: (- (get stake a) amount) }))
              (print "stake-slash")
              (ok true))
            ERR-INSUFFICIENT-STAKE)
        ERR-NOT-REGISTERED))))

;; ------------------------------------------------------------
;; READ-ONLY FUNCTIONS
;; ------------------------------------------------------------

(define-read-only (get-agent (agent-id uint))
  (map-get? agents { agent-id: agent-id }))

(define-read-only (get-agent-by-owner-read (owner principal))
  (map-get? agent-lookup { owner: owner }))

(define-read-only (get-config)
  {
    admin: (var-get admin),
    total-agents: (var-get total-agents),
    min-stake: (var-get min-stake),
    trade-fee: (var-get trade-fee)
  })
