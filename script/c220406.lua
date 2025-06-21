--Limit Break!!!
--Scripted by Hatter
local s,id=GetID()
function s.initial_effect(c)
	--Declare Attribute; Special Summon 1 "Limit Breaker" monster, then destroy 1 card you control
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.con)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	aux.GlobalCheck(s,function()
		s.attr_list={[0]=0,[1]=0}
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_PHASE+PHASE_END)
		ge1:SetCountLimit(1)
		ge1:SetOperation(function()
			s.attr_list[0]=0
			s.attr_list[1]=0
		end)
		Duel.RegisterEffect(ge1,0)
	end)
	Duel.AddCustomActivityCounter(id,ACTIVITY_CHAIN,function(re) return not re:IsActiveType(TYPE_QUICKPLAY) end)
end
-- "Limit Breaker" SetCode assumed to be 0xf86 (change if different)
function s.spfilter(c,attr,e,tp)
	return c:IsSetCard(0xf86) and c:IsAttribute(attr) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.con(e,tp,eg,ep,ev,re,r,rp,chk)
	return Duel.GetCustomActivityCount(id,tp,ACTIVITY_CHAIN)<=0
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		for i=0,6 do
			local attr=2^i
			if (s.attr_list[tp] & attr) == 0 and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,attr,e,tp) then
				return true
			end
		end
		return false
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATTRIBUTE)
	local allowed_attrs=0
	for i=0,6 do
		local attr=2^i
		if (s.attr_list[tp] & attr) == 0 and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,attr,e,tp) then
			allowed_attrs = allowed_attrs | attr
		end
	end
	local attr=Duel.AnnounceAttribute(tp,1,allowed_attrs)
	e:SetLabel(attr)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_MZONE)
end


function s.activate(e,tp,eg,ep,ev,re,r,rp)  
	local attr=e:GetLabel()
	if not attr then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,attr,e,tp)
	local c=e:GetHandler()
	if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local dg=Duel.SelectMatchingCard(tp,nil,tp,LOCATION_MZONE,0,1,1,nil)
		if #dg>0 then
			Duel.Destroy(dg,REASON_EFFECT)
		end
	end
	s.attr_list[tp] = s.attr_list[tp] | attr
	-- Register hint flags for declared attribute(s)
	
	-- Shuffle this card into the Deck instead of sending to GY
	
	-- Prevent activating Quick-Play Spells this turn
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetTargetRange(1,0)
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	aux.RegisterClientHint(e:GetHandler(),nil,tp,1,0,aux.Stringid(id,1),nil)
end
function s.aclimit(e,re,tp)
	return re:IsActiveType(TYPE_QUICKPLAY) and re:IsHasType(EFFECT_TYPE_ACTIVATE)
end
