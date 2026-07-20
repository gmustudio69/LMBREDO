--Pyrea V.S Eldrion
local s,id=GetID()

function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.actcon)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- Neither player can activate monster effects in response
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	Duel.SetChainLimitTillChainEnd(s.chainlm)
	return true
end

function s.chainlm(e,rp,tp)
	return not re:IsActiveType(TYPE_MONSTER)
end

----------------------------------------------------------
-- Rank 13 filter
----------------------------------------------------------

function s.spfilter(c,e,tp)
	return c:IsType(TYPE_XYZ)
		and c:IsRank(13)
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end

function s.rescon(sg,e,tp,mg)
	return sg:GetClassCount(Card.GetCode)==2
end

----------------------------------------------------------
-- Target
----------------------------------------------------------

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
			and aux.SelectUnselectGroup(
				Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_EXTRA,0,nil,e,tp),
				e,tp,2,2,s.rescon,0)
	end

	local g=Duel.GetMatchingGroup(Card.IsMonster,tp,
		LOCATION_MZONE,LOCATION_MZONE,nil)

	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_EXTRA)
end

----------------------------------------------------------
-- Activate
----------------------------------------------------------

function s.activate(e,tp,eg,ep,ev,re,r,rp)

	------------------------------------------------------
	-- Destroy all monsters
	------------------------------------------------------

	local dg=Duel.GetMatchingGroup(Card.IsMonster,tp,
		LOCATION_MZONE,LOCATION_MZONE,nil)

	if #dg>0 then
		Duel.Destroy(dg,REASON_EFFECT)
	end

	------------------------------------------------------
	-- Check zones
	------------------------------------------------------

	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if Duel.GetLocationCount(1-tp,LOCATION_MZONE)<=0 then return end

	------------------------------------------------------
	-- Select 2 Rank 13
	------------------------------------------------------

	local g=Duel.GetMatchingGroup(s.spfilter,tp,
		LOCATION_EXTRA,0,nil,e,tp)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local sg=aux.SelectUnselectGroup(
		g,e,tp,2,2,s.rescon,1,tp,HINTMSG_SPSUMMON)

	if not sg then return end

	Duel.ConfirmCards(1-tp,sg)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local g1=sg:Select(tp,1,1,nil)
	local tc1=g1:GetFirst()

	sg:RemoveCard(tc1)

	local tc2=sg:GetFirst()

	Duel.SpecialSummonStep(tc1,0,tp,tp,true,false,POS_FACEUP)
	Duel.SpecialSummonStep(tc2,0,tp,1-tp,true,false,POS_FACEUP)
	Duel.SpecialSummonComplete()
end