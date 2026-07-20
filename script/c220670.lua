--Pyrea V.S Eldrion
local s,id=GetID()

function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	--Neither player can chain monster effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetValue(s.aclimit)
	c:RegisterEffect(e2)
end

function s.aclimit(e,re,tp)
	return re:IsActiveType(TYPE_MONSTER)
end

function s.xyzfilter(c,e,tp)
	return c:IsRank(13)
		and c:IsType(TYPE_XYZ)
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,2,nil,e,tp)
	end

	local g=Duel.GetMatchingGroup(Card.IsDestructable,tp,
		LOCATION_MZONE,LOCATION_MZONE,nil)

	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)

	--Destroy all monsters
	local dg=Duel.GetMatchingGroup(Card.IsDestructable,tp,
		LOCATION_MZONE,LOCATION_MZONE,nil)

	if #dg>0 then
		Duel.Destroy(dg,REASON_EFFECT)
	end

	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0
		or Duel.GetLocationCount(1-tp,LOCATION_MZONE)<=0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local g=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,
		LOCATION_EXTRA,0,2,2,nil,e,tp)

	if #g~=2 then return end

	local tc1=g:GetFirst()
	local tc2=g:GetNext()

	if tc1:GetCode()==tc2:GetCode() then
		return
	end

	local you,opp

	if tc1:GetBaseAttack()<=tc2:GetBaseAttack() then
		you=tc1
		opp=tc2
	else
		you=tc2
		opp=tc1
	end

	if Duel.SpecialSummonStep(you,0,tp,tp,true,false,POS_FACEUP) then

		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(LOCATION_EXTRA)
		e1:SetReset(RESET_EVENT|RESETS_REDIRECT)
		you:RegisterEffect(e1,true)
	end

	if Duel.SpecialSummonStep(opp,0,tp,1-tp,true,false,POS_FACEUP) then

		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e2:SetValue(LOCATION_EXTRA)
		e2:SetReset(RESET_EVENT|RESETS_REDIRECT)
		opp:RegisterEffect(e2,true)
	end

	Duel.SpecialSummonComplete()

	local rg=Group.FromCards(you,opp)

	local e3=Effect.CreateEffect(e:GetHandler())
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_PHASE+PHASE_END)
	e3:SetCountLimit(1)
	e3:SetLabelObject(rg)
	e3:SetOperation(s.retop)
	e3:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e3,tp)
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetLabelObject()
	if not g then return end

	local rg=g:Filter(Card.IsAbleToExtra,nil)

	if #rg>0 then
		Duel.SendtoDeck(rg,nil,SEQ_DECKTOP,REASON_EFFECT)
	end
end