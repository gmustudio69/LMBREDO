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
	e2:SetCost(s.spcost)
	e2:SetCondition(function() return Duel.IsMainPhase() end)
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
function s.rmfilter2(c,tp)
	return c:IsAbleToRemoveAsCost()
		and (
			(c:IsSetCard(0x76b) and c:IsControler(tp))
			or
			(c:IsMonster() and c:IsFacedown())
		)
end
function s.spfilter(c,e,tp,ct)
	return c:IsSetCard(0x76b)
		and c:IsType(TYPE_LINK)
		and c:IsLink(ct)
		and not c:IsLink(1)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if not c:IsAbleToRemoveAsCost() then
		return false
	end

	local g=Duel.GetMatchingGroup(
	s.rmfilter2,
	tp,
	LOCATION_MZONE,
	LOCATION_MZONE,
	c,  -- exclude Fresnel
	tp
)
	
	local nums={}

	for i=0,#g do
	local link=i+1 -- Fresnel counts as 1

	if Duel.IsExistingMatchingCard(
		s.spfilter,tp,
		LOCATION_EXTRA,0,
		1,nil,e,tp,link
	) then
			table.insert(nums,link)
		end
	end

	if chk==0 then
		return #nums>0
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_LVRANK)

	local link=Duel.AnnounceNumber(tp,table.unpack(nums))
	local extra=link-1
	local rg=Group.CreateGroup()
		rg:AddCard(c)

	if extra>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local sg=g:Select(tp,extra,extra,nil)
		rg:Merge(sg)
	end

	Duel.Remove(rg,POS_FACEUP,REASON_COST)
	e:SetLabel(link)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end

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
	local ct=e:GetLabel()
	if not ct then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local g=Duel.SelectMatchingCard(
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

	local tc=g:GetFirst()

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