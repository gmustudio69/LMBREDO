-- Blastcore Detonator
local s,id=GetID()

function s.initial_effect(c)


	---------------------------------------------------
	-- Replacement: destroyed cards to GY → hand
	---------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_TO_GRAVE_REDIRECT)
	e0:SetRange(LOCATION_MZONE)
	e0:SetTarget(s.rmtarget)
	e0:SetTargetRange(LOCATION_ALL,LOCATION_ALL)
	e0:SetValue(LOCATION_HAND)
	c:RegisterEffect(e0)

	--On Normal or Special Summon: Destroy 1 FIRE monster with 0 DEF from hand, deck, or face-up field
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
	local e2_sp=e2:Clone()
	e2_sp:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2_sp)

	--Quick Effect: Destroy 1 other face-up card you control, then Special Summon 1 FIRE monster with 0 DEF from hand
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)

end
function s.rmtarget(e,c)
	return c:IsReason(REASON_DESTROY)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return eg:IsExists(s.repfilter,1,nil)
	end
	return true
end

function s.repval(e,c)
	return s.repfilter(c)
end
-- 1. Replacement Effect Functions
function s.redcon(e)
	-- Ensure the card is heading to the GY due to a card effect destruction
	local r=Duel.GetChainInfo(0,CHAININFO_REASON)
	return (r&REASON_EFFECT)~=0 and (r&REASON_DESTROY)~=0
end

function s.redtg(e,c)
	-- Exclude cards that were destroyed while in the hand
	return not c:IsLocation(LOCATION_HAND)
end

-- 2. Summon Trigger Functions
function s.desfilter(c)
	return c:IsAttribute(ATTRIBUTE_FIRE) and c:IsDefense(0) and c:IsDestructable()
		and (c:IsLocation(LOCATION_HAND|LOCATION_DECK) or c:IsFaceup())
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_HAND|LOCATION_DECK|LOCATION_MZONE|LOCATION_SZONE,0,1,nil) 
	end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_HAND|LOCATION_DECK|LOCATION_MZONE|LOCATION_SZONE)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_HAND|LOCATION_DECK|LOCATION_MZONE|LOCATION_SZONE,0,1,1,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

-- 3. Quick Effect Functions
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	-- Triggers when another card or effect is activated anywhere
	return re:GetHandler() ~= e:GetHandler()
end

function s.spfilter(c,e,tp)
	return c:IsAttribute(ATTRIBUTE_FIRE) and c:IsDefense(0) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		-- Must control another face-up card to destroy, and have a valid summon target in hand
		return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,LOCATION_ONFIELD,0,1,c)
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	-- Select another face-up card you control
	local dg=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,LOCATION_ONFIELD,0,1,1,c)
	if #dg>0 and Duel.Destroy(dg,REASON_EFFECT)>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		-- Proceed to Special Summon from hand if destruction is successful
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
		if #sg>0 then
			Duel.BreakEffect()
			Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end