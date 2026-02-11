--Limit Break!!!
local s,id=GetID()
local LIMIT_BREAKER=0xf86

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

function s.lbfilter(c,attr,e,tp)
	return c:IsSetCard(LIMIT_BREAKER)
		and c:IsAttribute(attr)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ✅ FIXED xyz filter
function s.xyzfilter(c,attr,mc,tp)
	return c:IsSetCard(LIMIT_BREAKER)
		and c:IsType(TYPE_XYZ)
		and c:IsAttribute(attr)
		and mc:IsCanBeXyzMaterial(c)
		and Duel.GetLocationCountFromEx(tp,tp,mc)>0
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return s.getmask(e,tp)~=0 end
	local mask=s.getmask(e,tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATTRIBUTE)
	local attr=Duel.AnnounceAttribute(tp,1,mask)
	e:SetLabel(attr)
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

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local attr=e:GetLabel()
	if attr==0 then return end

	-- STEP 1 — Special Summon
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

	-- CHECK if opponent controls monster (REQUIRED BY CARD TEXT)
	local opp_has_mon=Duel.IsExistingMatchingCard(Card.IsMonster,tp,0,LOCATION_MZONE,1,nil)

	-- CHECK XYZ POSSIBILITY
	local can_xyz=false
	if opp_has_mon then
		can_xyz=Duel.IsExistingMatchingCard(function(c)
			return c:IsFaceup() and c:IsSetCard(LIMIT_BREAKER)
				and c:IsAttribute(attr)
				and Duel.IsExistingMatchingCard(s.xyzfilter,tp,
					LOCATION_EXTRA,0,1,nil,attr,c,tp)
		end,tp,LOCATION_MZONE,0,1,nil)
	end

	if can_xyz and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		-- Xyz branch
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
		-- DESTROY branch
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectMatchingCard(tp,function(c) return c:IsFaceup() end,tp,LOCATION_MZONE,0,1,1,nil)
		if #g>0 then
			Duel.Destroy(g,REASON_EFFECT)
		end
	end

	s.attr_list[tp]=s.attr_list[tp]|attr
end
