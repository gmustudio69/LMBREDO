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

	--Neither player can activate monster effects in response
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetCode(EFFECT_CANNOT_INACTIVATE)
	c:RegisterEffect(e2)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,2,nil,e,tp)
	end

	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,
		Duel.GetFieldGroupCount(tp,LOCATION_MZONE,LOCATION_MZONE),
		0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_EXTRA)
end

function s.spfilter(c,e,tp)
	return c:IsRank(13)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SPECIAL,tp,false,false)
end

function s.rescon(sg,e,tp,mg)
	return sg:GetClassCount(Card.GetCode)==2
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)

	------------------------------------------------
	-- Destroy all monsters
	------------------------------------------------
	local dg=Duel.GetMatchingGroup(Card.IsDestructable,tp,
		LOCATION_MZONE,LOCATION_MZONE,nil)

	if #dg>0 then
		Duel.Destroy(dg,REASON_EFFECT)
	end

	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if Duel.GetLocationCount(1-tp,LOCATION_MZONE)<=0 then return end

	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_EXTRA,0,nil,e,tp)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local sg=aux.SelectUnselectGroup(
		g,e,tp,2,2,s.rescon,1,tp,HINTMSG_SPSUMMON)

	if not sg or #sg~=2 then return end

	local tc1,tc2=sg:GetFirst(),sg:GetNext()

	local you,opp

	if tc1:GetAttack()<tc2:GetAttack() then
		you=tc1
		opp=tc2
	elseif tc2:GetAttack()<tc1:GetAttack() then
		you=tc2
		opp=tc1
	else
		Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_SPSUMMON)
		local cg=sg:Select(1-tp,1,1,nil)
		you=cg:GetFirst()
		opp=sg:GetFirst()
		if opp==you then
			opp=sg:GetNext()
		end
	end

	if Duel.SpecialSummon(you,0,tp,tp,false,false,POS_FACEUP)==0 then
		return
	end

	Duel.SpecialSummon(opp,0,tp,1-tp,false,false,POS_FACEUP)

	------------------------------------------------
	-- Return during End Phase
	------------------------------------------------
	local rg=Group.FromCards(you,opp)

	for tc in aux.Next(rg) do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_PHASE+PHASE_END)
		e1:SetCountLimit(1)
		e1:SetReset(RESET_PHASE|PHASE_END)
		e1:SetLabelObject(tc)
		e1:SetOperation(s.retop)
		Duel.RegisterEffect(e1,tp)
	end
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if tc and tc:IsLocation(LOCATION_MZONE) then
		Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end

function s.checkop(e,lp,tp)
	return re:IsMonsterEffect()
end