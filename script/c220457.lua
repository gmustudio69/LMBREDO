--<Limit Breaker> Shadow Catastrophe
local s,id=GetID()
function s.initial_effect(c)
	--Set Limit S/T
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_LEAVE_GRAVE+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetRange(LOCATION_GRAVE)
	e1:SetCountLimit(1,{id,3})
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	-- 2: Place 1 "Limit" Continuous Spell/Trap from Hand or Deck
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(function(e,tp) return Duel.IsMainPhase() end)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_PHASE)
	e2:SetTarget(s.postg)
	e2:SetOperation(s.posop)
	c:RegisterEffect(e2)
	-- Effect 2: Special Summon Token when sent to GY
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_TOKEN)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

-- ==========================================
-- Xử lý Effect 1 (Send & Equip)
-- ==========================================
-- E2: Place Continuous S/T
function s.posfilter(c)
	return c:IsSetCard(0xf86) and c:IsType(TYPE_CONTINUOUS) and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) and not c:IsForbidden()
-- Updated Target Function
end
function s.postg(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1 = Duel.GetLocationCount(tp,LOCATION_SZONE)>0 
			   and Duel.IsExistingMatchingCard(s.spellfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil)
	local b2 = Duel.CheckLPCost(tp,800) 
			   and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 
			   and Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_DECK,0,1,nil,220407)

	if chk==0 then return b1 or b2 end
	
	local op = -1
	if b1 and b2 then
		op = Duel.SelectOption(tp, aux.Stringid(id,1), aux.Stringid(id,2)) -- Option 1 or 2
	elseif b1 then
		op = Duel.SelectOption(tp, aux.Stringid(id,1)) -- Only Option 1
	else
		op = Duel.SelectOption(tp, aux.Stringid(id,2)) + 1 -- Only Option 2
	end	
   e:SetLabel(op) -- Store the choice here
	   -- Set Category and Operation Info dynamically based on selection
	if op==0 then
		e:SetCategory(CATEGORY_TOFIELD)
		Duel.SetOperationInfo(0,CATEGORY_TOFIELD,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
	else
		e:SetCategory(CATEGORY_SPECIAL_SUMMON) -- Placeholder for your
	end
end

-- Updated Operation Function
function s.posop(e,tp,eg,ep,ev,re,r,rp)
	local op = e:GetLabel() -- Retrieve the choice-
	if op==0 then
		-- Logic for placing Continuous Spell/Trap
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
		local tc=Duel.SelectMatchingCard(tp,s.posfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil):GetFirst()
		if tc then Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true) end
	else
		-- Logic for "Limit Break - Install"
		Duel.Damage(tp,800,REASON_EFFECT)
		local tc=Duel.GetFirstMatchingCard(Card.IsCode,tp,LOCATION_DECK,0,nil,220407)
		if tc then 
			Duel.SSet(tp,tc)
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
			e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
			e1:SetCondition(s.actcon) -- Check for opponent's non-DARK extra deck monster
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
		end
	end
end

-- New Condition for "Install" activation
function s.actcon(e)
	local c=e:GetHandler()
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(function(c) 
		return c:IsLocation(LOCATION_MZONE) and c:IsControler(1-tp) 
			   and c:IsSummonLocation(LOCATION_EXTRA) and not c:IsAttribute(ATTRIBUTE_DARK) 
	end,tp,0,LOCATION_MZONE,1,nil)
end
-- E3: Special Summon DARK Warrior from GY
function s.spfilter(c,e,tp)
	return c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_WARRIOR) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,1,1,nil,e,tp):GetFirst()
	if tc then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end
function s.targetfilter(c)
	return c:IsDestructable()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.targetfilter,tp,LOCATION_ONFIELD,0,1,c,tp)
		and c:IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,tp,LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local exc=c:IsRelateToEffect(e) and c or nil
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.targetfilter,tp,LOCATION_ONFIELD,0,1,1,exc,tp)
	if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 and c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end