--Elysia, Priest of the Endless
local s,id=GetID()
function s.initial_effect(c)
	-- Cannot be Normal Summoned/Set
	c:EnableUnsummonable()

	-- Becomes "<World Decoder> Ellie" while on the field
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(CARD_ELLIE)
	c:RegisterEffect(e1)

	-- Special Summon from Hand or SZone by sending 1 other S/T to GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_HAND+LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- On Special Summon: Place monster as Cont. Spell OR Set S/T from Deck
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetCountLimit(1,id+100)
	e3:SetTarget(s.efftg)
	e3:SetOperation(s.effop)
	c:RegisterEffect(e3)
end

-- ==========================================
-- Definitions & Constants
-- ==========================================
local SET_WORLD_DECODER = 0xb67 -- Replace with your actual "World Decoder" archetype setcode
local CARD_ELLIE		= 220405 -- Replace with the exact ID of "<World Decoder> Ellie"

-- ==========================================
-- E2: Special Summon Logic
-- ==========================================
function s.costfilter(c,e,tp)
	return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToGraveAsCost()
		and (c:IsLocation(LOCATION_HAND) or c:IsFaceup())
		and not c:IsCode(id)
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,c,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,c,e,tp)
	Duel.SendtoGrave(g,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- ==========================================
-- E3: Modal On-Special-Summon Logic
-- ==========================================
-- Filter for Option 1: World Decoder monster from Deck to SZone as Continuous Spell
function s.tfilter(c)
	return c:IsSetCard(SET_WORLD_DECODER) and c:IsType(TYPE_MONSTER) and not c:IsForbidden()
end

-- Filter for Option 2: World Decoder Spell/Trap to Set from Deck
function s.setfilter(c)
	return c:IsSetCard(SET_WORLD_DECODER) and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) and c:IsSSetable()
end

function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1 = Duel.GetLocationCount(tp,LOCATION_SZONE)>0 
		and Duel.IsExistingMatchingCard(s.tfilter,tp,LOCATION_DECK,0,1,nil)
	local b2 = Duel.GetLocationCount(tp,LOCATION_SZONE)>0 
		and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)

	if chk==0 then return b1 or b2 end

	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
	elseif b1 then
		op=Duel.SelectOption(tp,aux.Stringid(id,2))
	else
		op=Duel.SelectOption(tp,aux.Stringid(id,3))+1
	end
	e:SetLabel(op)
end

function s.effop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	local op=e:GetLabel()

	if op==0 then
		-- Option 1: Place 1 "World Decoder" monster from Deck face-up as Continuous Spell
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
		local g=Duel.SelectMatchingCard(tp,s.tfilter,tp,LOCATION_DECK,0,1,1,nil)
		local tc=g:GetFirst()
		if tc then
			Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetCode(EFFECT_CHANGE_TYPE)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetValue(TYPE_SPELL+TYPE_CONTINUOUS)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET)
			tc:RegisterEffect(e1)
		end
	elseif op==1 then
		-- Option 2: Set 1 "World Decoder" Spell/Trap directly from Deck
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
		local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SSet(tp,g)
		end
	end
end