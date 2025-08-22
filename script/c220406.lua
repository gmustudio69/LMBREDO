--Limit Break!!!
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.con)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--Track declared Attributes per player
	aux.GlobalCheck(s,function()
		s.attr_list={[0]=0,[1]=0}
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_PHASE_START+PHASE_DRAW)
		ge1:SetOperation(function()
			s.attr_list[0]=0
			s.attr_list[1]=0
		end)
		Duel.RegisterEffect(ge1,0)
	end)
	--Quick-Play activity counter
	Duel.AddCustomActivityCounter(id,ACTIVITY_CHAIN,function(re) return not re:IsActiveType(TYPE_QUICKPLAY) end)
end
-- "Limit Breaker" SetCode assumed to be 0xf86
function s.lbfilter(c,attr,e,tp)
	return c:IsSetCard(0xf86) and c:IsAttribute(attr) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.xyzfilter(c,attr,mc,tp)
	return c:IsSetCard(0xf86) and c:IsType(TYPE_XYZ) and c:IsAttribute(attr)
		and mc:IsCanBeXyzMaterial(c) and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
end
function s.con(e,tp)
	return Duel.GetCustomActivityCount(id,tp,ACTIVITY_CHAIN)<=0
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		for i=0,6 do
			local attr=2^i
			if (s.attr_list[tp] & attr) == 0
				and (Duel.IsExistingMatchingCard(s.lbfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,attr,e,tp)
				or Duel.IsExistingMatchingCard(function(c) return c:IsFaceup() and c:IsSetCard(0xf86) and c:IsAttribute(attr) end,tp,LOCATION_MZONE,0,1,nil)) then
				return true
			end
		end
		return false
	end
	local allowed_attrs=0
	for i=0,6 do
		local attr=2^i
		if (s.attr_list[tp] & attr) == 0
			and (Duel.IsExistingMatchingCard(s.lbfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,attr,e,tp)
			or Duel.IsExistingMatchingCard(function(c) return c:IsFaceup() and c:IsSetCard(0xf86) and c:IsAttribute(attr) end,tp,LOCATION_MZONE,0,1,nil)) then
			allowed_attrs = allowed_attrs | attr
		end
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATTRIBUTE)
	local attr=Duel.AnnounceAttribute(tp,1,allowed_attrs)
	e:SetLabel(attr)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetPossibleOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_MZONE)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local attr=e:GetLabel()
	if not attr then return end
	local opp_has_mon=Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_MZONE,1,nil)
	local b1=Duel.IsExistingMatchingCard(s.lbfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,attr,e,tp)
	local b2=Duel.IsExistingMatchingCard(function(c) return c:IsFaceup() and c:IsSetCard(0xf86) and c:IsAttribute(attr)
			and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,attr,c,tp)
	end,tp,LOCATION_MZONE,0,1,nil)
	--Effect 1
	local op=nil
	if not opp_has_mon then
		op=Duel.SelectEffect(tp,
			{b1,aux.Stringid(id,1)},
			{b2,aux.Stringid(id,2)})
	end
	local breakeffect=false
	if (op and op==1) or (opp_has_mon and b1 and (not b2 or Duel.SelectYesNo(tp,aux.Stringid(id,1)))) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local g=Duel.SelectMatchingCard(tp,s.lbfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,attr,e,tp)
			if #g>0 then
				Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
				b2=Duel.IsExistingMatchingCard(function(c) return c:IsFaceup() and c:IsSetCard(0xf86) and c:IsAttribute(attr)
			and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,attr,c,tp)
	end,tp,LOCATION_MZONE,0,1,nil)
				if not opp_has_mon then 
				   if Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_MZONE,0,1,nil) then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
					local dg=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_MZONE,0,1,1,nil)
						if #dg>0 then
						   Duel.Destroy(dg,REASON_EFFECT) 
						end
					end
				end 
			end
		breakeffect=true
	end
	if (op and op==2) or (opp_has_mon and b2 and (not breakeffect or Duel.SelectYesNo(tp,aux.Stringid(id,2)))) then
			if breakeffect then Duel.BreakEffect() end
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
			local mc=Duel.SelectMatchingCard(tp,function(c)
				return c:IsFaceup() and c:IsSetCard(0xf86) and c:IsAttribute(attr)
					and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,attr,c,tp)
			end,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
			if mc then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local xyz=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,attr,mc,tp):GetFirst()
				if xyz then
					local mg=mc:GetOverlayGroup()
					if #mg>0 then Duel.Overlay(xyz,mg) end
					xyz:SetMaterial(Group.FromCards(mc))
					Duel.Overlay(xyz,Group.FromCards(mc))
					Duel.SpecialSummon(xyz,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
					xyz:CompleteProcedure()
				end
			end
		end
	s.attr_list[tp] = s.attr_list[tp] | attr
	--Prevent activating Quick-Play Spells this turn
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,4))
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetTargetRange(1,0)
	e1:SetValue(s.aclimit)
	Duel.RegisterEffect(e1,tp)
end
function s.aclimit(e,re,tp)
	return re:IsActiveType(TYPE_QUICKPLAY) and re:IsHasType(EFFECT_TYPE_ACTIVATE)
end
