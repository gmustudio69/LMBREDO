-- <World Decoder> Obliterated Future
local s,id=GetID()
function s.initial_effect(c)
	-- This card becomes "<World Decoder> Ellie" while on the field
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(220405) -- REPLACE WITH ELLIE'S ID (e.g., 10000000)
	c:RegisterEffect(e1)

	-- Special Summon from Hand or S/T Zone
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_HAND|LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.spcon)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- Place this card and 1 "World Decoder" in S/T Zone
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+1) -- Separate HOPT
	e3:SetTarget(s.pltg)
	e3:SetOperation(s.plop)
	c:RegisterEffect(e3)
end

-- ==========================================
-- CUSTOM SETCODES AND IDS (Replace these)
-- ==========================================
s.SET_LIMIT = 0xf86 -- Replace with your "Limit" setcode
s.SET_WORLD_DECODER = 0xb67 -- Replace with your "World Decoder" setcode
local CARD_ELLIE_ID = 220405 -- Replace with <World Decoder> Ellie's Card ID
-- ==========================================

-- Effect 2: Special Summon Functions
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- If in S/T zone, it must be a face-up Continuous Spell
	if c:IsLocation(LOCATION_SZONE) then
		return c:IsFaceup() and c:GetType()==TYPE_SPELL+TYPE_CONTINUOUS
	end
	return true
end
function s.cfilter(c)
	return c:IsSetCard(s.SET_LIMIT) and c:IsType(TYPE_MONSTER) and c:IsAbleToGraveAsCost()
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,1,nil)
	-- Save the attribute of the sent monster for the restriction
	e:SetLabel(g:GetFirst():GetAttribute())
	Duel.SendtoGrave(g,REASON_COST)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		local att=e:GetLabel()
		-- Restriction: Cannot Special Summon from Deck/Extra Deck, except same attribute
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetTargetRange(1,0)
		e1:SetTarget(s.splimit)
		e1:SetLabel(att)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	-- Applies only to Deck and Extra Deck
	return c:IsLocation(LOCATION_DECK|LOCATION_EXTRA) and not c:IsAttribute(e:GetLabel())
end

-- Effect 3: Place in S/T Zone Functions
function s.plfilter(c)
	return c:IsSetCard(s.SET_WORLD_DECODER) and c:IsType(TYPE_MONSTER) and not c:IsForbidden()
end
function s.pltg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Requires at least 2 open S/T zones (1 for this card, 1 for the deck/hand monster)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>=2
		and Duel.IsExistingMatchingCard(s.plfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,nil) end
end
function s.plop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<2 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.plfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		-- Move the target monster to S/T Zone as Continuous Spell
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
		local e1=Effect.CreateEffect(c)
		e1:SetCode(EFFECT_CHANGE_TYPE)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET)
		e1:SetValue(TYPE_SPELL+TYPE_CONTINUOUS)
		tc:RegisterEffect(e1)
		
		-- Move this card to S/T Zone as Continuous Spell
		if c:IsRelateToEffect(e) and c:IsControler(tp) and not c:IsImmuneToEffect(e) then
			Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
			local e2=Effect.CreateEffect(c)
			e2:SetCode(EFFECT_CHANGE_TYPE)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET)
			e2:SetValue(TYPE_SPELL+TYPE_CONTINUOUS)
			c:RegisterEffect(e2)
		end
	end
end