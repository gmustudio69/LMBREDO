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
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.lktg)
	e2:SetOperation(s.lkop)
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
function s.costfilter(c)
	return c:IsAbleToRemove()and (c:IsSetCard(0x76b) or (c:IsMonster() and c:IsFacedown()))
end
function s.lkfilter(c,e,tp,ct)
	return c:IsSetCard(0x76b) and c:IsType(TYPE_LINK) and c:IsLink(ct) c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP)and Duel.GetLocationCountFromEx(tp,tp,g,c)>0
end
function s.lktg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.costfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if chk==0 then
		return #g>0 and Duel.GetLocationCountFromEx(tp,tp,e:GetHandler())>0 and Duel.IsExistingMatchingCard(s.lkfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,1)
	end
end
function s.exfilter(c,e,tp)
	return c:IsSetCard(0x76b)
		and c:IsType(TYPE_LINK)
		and c:IsCanBeSpecialSummoned(
			e,SUMMON_TYPE_LINK,tp,false,false)
end

function s.lkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.costfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)

	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local sg=aux.SelectUnselectGroup(g,e,tp,1,#g,
		function(sg)
			local ct=#sg
			return Duel.IsExistingMatchingCard(
				s.lkfilter,tp,
				LOCATION_EXTRA,0,
				1,nil,e,tp,ct)
		end,
		1,tp,HINTMSG_REMOVE)

	if not sg or #sg==0 then return end

	local ct=#sg

	if Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)==0 then
		return
	end

	if Duel.GetLocationCountFromEx(tp,tp,nil)<=0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local tg=Duel.SelectMatchingCard(
		tp,
		s.lkfilter,
		tp,
		LOCATION_EXTRA,
		0,
		1,1,nil,
		e,tp,ct)

	local tc=tg:GetFirst()

	if tc then
		Duel.SpecialSummon(tc,
			SUMMON_TYPE_LINK,
			tp,tp,
			false,false,
			POS_FACEUP)
		tc:CompleteProcedure()
	end
end