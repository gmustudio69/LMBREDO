--World Decoder Spell
local s,id=GetID()
function s.initial_effect(c)
	-- Activate: Reveal 1 World Decoder Synchro -> Search or SS 1 monster with same Attribute
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	--GY Cost Replace: Banish this card from GY instead of discarding/sending for a "World Decoder" cost
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_COST_REPLACE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetTarget(s.reptg)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)
end

-- Archetype definition (Replace 0x999 with your actual "World Decoder" setcode)
local SET_WORLD_DECODER = 0xb67

-- Extra Deck Reveal Filter: Must be a "World Decoder" Synchro monster
function s.revfilter(c,e,tp)
	if not (c:IsSetCard(SET_WORLD_DECODER) and c:IsType(TYPE_SYNCHRO) and not c:IsPublic()) then return false end
	local att=c:GetAttribute()
	return Duel.IsExistingMatchingCard(s.thspfilter,tp,LOCATION_DECK,0,1,nil,e,tp,att)
end

-- Deck Target Filter: "World Decoder" monster with matching Attribute
function s.thspfilter(c,e,tp,att)
	return c:IsSetCard(SET_WORLD_DECODER) and c:IsType(TYPE_MONSTER) and c:IsAttribute(att)
		and (c:IsAbleToHand() or (Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false)))
end

-- Field Check Filter: Check if you control a "World Decoder" monster with a DIFFERENT Attribute
function s.diffattfilter(c,att)
	return c:IsFaceup() and c:IsSetCard(SET_WORLD_DECODER) and not c:IsAttribute(att)
end

-- 1. Activation Target & Operation
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.revfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local revg=Duel.SelectMatchingCard(tp,s.revfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	if #revg==0 then return end
	
	local revcard=revg:GetFirst()
	Duel.ConfirmCards(1-tp,revcard)
	local att=revcard:GetAttribute()

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thspfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp,att)
	local tc=g:GetFirst()
	if not tc then return end

	-- Check if you control a World Decoder monster with a different attribute
	local can_ss=Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and tc:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.IsExistingMatchingCard(s.diffattfilter,tp,LOCATION_MZONE,0,1,nil,att)

	-- Player choice: Add to hand OR Special Summon if condition is met
	if can_ss and Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))==1 then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	else
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	end
end
-- E2: Cost Replacement (Banishing from GY)
--------------------------------------------------------------------------------

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	-- Check if the cost is for a "World Decoder" card and this card is able to be banished
	if chk==0 then
		return c:IsAbleToRemoveAsCost() 
			and re and re:GetHandler():IsSetCard(SET_WORLD_DECODER)
			and (r&REASON_COST)~=0
	end
	return Duel.SelectEffectYesNo(tp,c,96)
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end