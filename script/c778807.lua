-- Follower of the Moon, Fresnel
local s,id,o=GetID()
function s.initial_effect(c)
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(s.linkmatfilter),1,1)
	c:EnableReviveLimit()
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,{id,1})
	e1:SetTarget(s.rmtg)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1)
	-- Quick Link Climb
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetCountLimit(1,{id,2})
	--e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end
function s.linkmatfilter(c)
	return c:IsSetCard(0x76b) and not c:IsRace(RACE_WARRIOR)
end
function s.rmfilter(c)
	return c:IsAbleToRemove()
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_GRAVE)
			and s.rmfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.rmfilter,tp,
			LOCATION_GRAVE,LOCATION_GRAVE,
			1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g=Duel.SelectTarget(
		tp,s.rmfilter,
		tp,LOCATION_GRAVE,LOCATION_GRAVE,
		1,1,nil)

	Duel.SetOperationInfo(
		0,CATEGORY_REMOVE,g,1,0,0)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if tc and tc:IsRelateToEffect(e) then
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end
function s.rmfilter2(c)
	return c:IsAbleToRemoveAsCost()
		and (
			c:IsSetCard(0x76b)
			or (c:IsMonster() and c:IsFacedown())
		)
end
function s.spfilter(c,e,tp,ct,g)
	return c:IsSetCard(0x76b)
		and c:IsType(TYPE_LINK)
		and c:IsLink(ct)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.GetLocationCountFromEx(tp,tp,g,c)>0
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(
		function(c) return s.rmfilter2(c,e) end,
		tp,
		LOCATION_MZONE,
		LOCATION_MZONE,
		nil
	)

	local nums={}

	for i=1,#g do
		if Duel.IsExistingMatchingCard(
			s.spfilter,tp,
			LOCATION_EXTRA,0,
			1,nil,e,tp,i
		) then
			table.insert(nums,i)
		end
	end

	if chk==0 then
		return #nums>0
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		nil,
		1,
		0,
		LOCATION_MZONE
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_EXTRA
	)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(
		function(c) return s.rmfilter2(c,e) end,
		tp,
		LOCATION_MZONE,
		LOCATION_MZONE,
		nil
	)

	local nums={}

	for i=1,#g do
		if Duel.IsExistingMatchingCard(
			s.spfilter,tp,
			LOCATION_EXTRA,0,
			1,nil,e,tp,i
		) then
			table.insert(nums,i)
		end
	end

	if #nums==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_LVRANK)
	local ct=Duel.AnnounceNumber(tp,table.unpack(nums))

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local rg=g:Select(tp,ct,ct,nil)

	local removed=Duel.Remove(
		rg,
		POS_FACEUP,
		REASON_EFFECT
	)

	if removed~=ct then
		return
	end

	if Duel.GetLocationCountFromEx(tp,tp,nil)<=0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local sg=Duel.SelectMatchingCard(
		tp,
		s.spfilter,
		tp,
		LOCATION_EXTRA,
		0,
		1,
		1,
		nil,
		e,tp,ct
	)

	local tc=sg:GetFirst()

	if tc then
		Duel.SpecialSummon(
			tc,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP
		)
	end
end