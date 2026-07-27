--Attri, the spirit forest
local s,id=GetID()
function s.initial_effect(c)
	-- Activate Field Spell
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- Effect 1: Add "<Limit Breaker> Kazari" or Spirit monster from Deck to hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_FZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- Effect 2: Set 1 "Limit" Spell/Trap that mentions "<Limit Breaker> Kazari"
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.setcon)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end

-- ==========================================
-- Definitions & Constants
-- ==========================================
local CARD_KAZARI = 220450-- REPLACE with the exact Card ID of "<Limit Breaker> Kazari"
local SET_LIMIT = 0xf86	  -- REPLACE with your "Limit" archetype setcode if applicable

-- ==========================================
-- E1: Search Kazari or Spirit Monster
-- ==========================================
function s.thfilter(c)
	return (c:IsCode(CARD_KAZARI) or c:IsType(TYPE_SPIRIT)) 
		and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- ==========================================
-- E2: Set "Limit" S/T mentioning Kazari
-- ==========================================
-- Check for Monster Cards treated as Continuous Spells on the field
function s.conspellfilter(c)
	return c:IsFaceup() and c:IsMonsterCard() and c:IsContinuousSpell()
end

function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.conspellfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,2,nil)
end

-- Filter for "Limit" Spell/Traps that mention Kazari
function s.setfilter(c)
	return c:IsSetCard(SET_LIMIT) and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP))
		and c:ListsCode(220450) and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g)
	end
end