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

	-- Substitute Cost: Banish this card from GY instead of discarding/sending for World Decoder effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_DISCARD_COST_CHANGE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.subtg)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_SEND_REPLACE)
	c:RegisterEffect(e3)
end

-- Archetype definition (Replace 0x999 with your actual "World Decoder" setcode)
local SET_WORLD_DECODER = 0x999

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

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_OPERATECARD)
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

-- 2. Cost Substitution Logic
function s.subtg(e,re,rp)
	-- Verifies the effect being activated belongs to a "World Decoder" card
	return re and re:GetHandler():IsSetCard(SET_WORLD_DECODER)
end