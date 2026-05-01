local s,id=GetID()
local LIMIT_BREAKER=0xf86

function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY+CATEGORY_DAMAGE)
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

function s.xyzfilter(c,attr,mc)
	return c:IsSetCard(LIMIT_BREAKER)
		and c:IsType(TYPE_XYZ)
		and c:IsAttribute(attr)
		and mc:IsCanBeXyzMaterial(c)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Allow activation if at least one attribute hasn't been used yet
	if chk==0 then return s.attr_list[tp] ~= 0x7f end 
	
	-- The mask now only excludes already-declared attributes
	local mask = 0x7f ~ s.attr_list[tp]
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATTRIBUTE)
	local attr=Duel.AnnounceAttribute(tp,1,mask)
	e:SetLabel(attr)
	
	-- Update the tracker immediately upon declaration
	s.attr_list[tp] = s.attr_list[tp]|attr
	
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,tp,800)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local attr=e:GetLabel()
	if attr==0 then return end
	
	-- 1. Take 800 damage
	if Duel.Damage(tp,800,REASON_EFFECT) > 0 then
		-- 2. Optional Special Summon
		if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
			and Duel.IsExistingMatchingCard(s.lbfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,attr,e,tp) 
			and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local g=Duel.SelectMatchingCard(tp,s.lbfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,attr,e,tp)
			if #g>0 then
				Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
			end
		end
	end

	Duel.BreakEffect()

	-- 3. Branching Path: Xyz Summon OR Destroy
	local opp_has_mon=Duel.IsExistingMatchingCard(Card.IsMonster,tp,0,LOCATION_MZONE,1,nil)
	local can_xyz = opp_has_mon and Duel.IsExistingMatchingCard(function(c)
		return c:IsFaceup() and c:IsSetCard(LIMIT_BREAKER) and c:IsAttribute(attr)
			and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,attr,c)
	end,tp,LOCATION_MZONE,0,1,nil)

	if can_xyz and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		-- Perform Xyz Summon
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local mc=Duel.SelectMatchingCard(tp,function(c)
			return c:IsFaceup() and c:IsSetCard(LIMIT_BREAKER) and c:IsAttribute(attr)
				and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,attr,c)
		end,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()

		if mc then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local xyz=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,attr,mc):GetFirst()
			if xyz then
				local mg=mc:GetOverlayGroup()
				if #mg>0 then Duel.Overlay(xyz,mg) end
				Duel.Overlay(xyz,mc)
				Duel.SpecialSummon(xyz,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
				xyz:CompleteProcedure()
			end
		end
	else
		-- Forced Destruction (Normal Path)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local dg=Duel.SelectMatchingCard(tp,nil,tp,LOCATION_MZONE,0,1,1,nil)
		if #dg>0 then 
			Duel.Destroy(dg,REASON_EFFECT) 
		end
	end
end