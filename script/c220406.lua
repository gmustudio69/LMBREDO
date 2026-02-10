--Limit Break!!!
local s,id=GetID()

function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	--Attribute tracker
	aux.GlobalCheck(s,function()
		s.attr_list={[0]=0,[1]=0}
		local ge=Effect.CreateEffect(c)
		ge:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge:SetCode(EVENT_PHASE_START+PHASE_DRAW)
		ge:SetOperation(function()
			s.attr_list[0]=0
			s.attr_list[1]=0
		end)
		Duel.RegisterEffect(ge,0)
	end)
end

--Limit Breaker setcode
local LIMIT_BREAKER=0xf86

function s.lbfilter(c,attr,e,tp)
	return c:IsSetCard(LIMIT_BREAKER) and c:IsAttribute(attr)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.xyzfilter(c,attr,mc,tp)
	return c:IsSetCard(LIMIT_BREAKER) and c:IsType(TYPE_XYZ)
		and c:IsAttribute(attr)
		and mc:IsCanBeXyzMaterial(c)
		and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
end

--ATTRIBUTE SELECT
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return s.getmask(e,tp)~=0 end
	local mask=s.getmask(e,tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATTRIBUTE)
	local attr=Duel.AnnounceAttribute(tp,1,mask)
	e:SetLabel(attr)

	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,
		LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_MZONE)
end

function s.getmask(e,tp)
	local mask=0
	for i=0,6 do
		local attr=2^i
		if s.attr_list[tp]&attr==0 and (
			Duel.IsExistingMatchingCard(s.lbfilter,tp,
				LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,attr,e,tp)
			or Duel.IsExistingMatchingCard(function(c)
				return c:IsFaceup() and c:IsSetCard(LIMIT_BREAKER)
					and c:IsAttribute(attr)
			end,tp,LOCATION_MZONE,0,1,nil)
		) then
			mask=mask|attr
		end
	end
	return mask
end

--MAIN RESOLVE
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local attr=e:GetLabel()
	if attr==0 then return end

	--STEP 1 — Special Summon
	if Duel.IsExistingMatchingCard(s.lbfilter,tp,
		LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,attr,e,tp)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.lbfilter,tp,
			LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,attr,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end

	Duel.BreakEffect()

	local can_xyz=false
	if Duel.GetMatchingGroupCount(nil,tp,0,LOCATION_MZONE,nil)>0 and Duel.GetLocationCountFromEx(tp)>0 then
		can_xyz=Duel.IsExistingMatchingCard(function(c)
			return c:IsFaceup() and c:IsSetCard(LIMIT_BREAKER)
				and c:IsAttribute(attr)
				and Duel.IsExistingMatchingCard(s.xyzfilter,tp,
					LOCATION_EXTRA,0,1,nil,attr,c,tp)
		end,tp,LOCATION_MZONE,0,1,nil)
	end

	local do_xyz=false
	if can_xyz then
		do_xyz=Duel.SelectYesNo(tp,aux.Stringid(id,2))
	end

	if do_xyz then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local mc=Duel.SelectMatchingCard(tp,function(c)
			return c:IsFaceup() and c:IsSetCard(LIMIT_BREAKER)
				and c:IsAttribute(attr)
				and Duel.IsExistingMatchingCard(s.xyzfilter,tp,
					LOCATION_EXTRA,0,1,nil,attr,c,tp)
		end,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()

		if mc then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local xyz=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,
				LOCATION_EXTRA,0,1,1,nil,attr,mc,tp):GetFirst()

			if xyz then
				local mg=mc:GetOverlayGroup()
				if #mg>0 then Duel.Overlay(xyz,mg) end
				Duel.Overlay(xyz,mc)
				Duel.SpecialSummon(xyz,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
				xyz:CompleteProcedure()
			end
		end

	else
		--destroy fallback
		if Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_MZONE,0,1,nil) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_MZONE,0,1,1,nil)
			Duel.Destroy(g,REASON_EFFECT)
		end
	end

	--mark attribute used
	s.attr_list[tp]=s.attr_list[tp]|attr
end
