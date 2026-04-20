--Limit Break - The Endless One
local s,id=GetID()
function s.initial_effect(c)
	--Counter Trap activation
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DISABLE_SUMMON+CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_SPSUMMON) -- (Lưu ý: Nếu muốn chặn cả Normal/Flip summon thì phải đăng ký thêm event)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

--Check summon negatable
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	-- Đã xóa Duel.IsChainNegatable(ev) vì Inherent Summon không tạo Chain Link
	return Duel.GetCurrentChain()==0
end

--Filters
-- SỬA LỖI: Truyền thêm 'tp' vào filter để CheckRemoveOverlayCard hoạt động
function s.xyzfilter(c,tp)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsSetCard(0xf86)
	and c:CheckRemoveOverlayCard(tp,1,REASON_COST)
end

function s.synfilter(c)
	-- LƯU Ý: Hãy chắc chắn quái thú Synchro của bạn đang test thực sự là Level 13
	return c:IsFaceup() and c:IsType(TYPE_SYNCHRO) and c:IsLevel(13)
end

--Cost
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	-- SỬA LỖI: Truyền 'tp' vào cuối hàm kiểm tra filter
	local b1=Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil,tp)
	local b2=Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_MZONE,0,1,nil)

	if chk==0 then return b1 or b2 end

	if not b2 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DEATTACHFROM)
		local g=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil,tp)
		g:GetFirst():RemoveOverlayCard(tp,1,1,REASON_COST)
	elseif b1 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DEATTACHFROM)
		local g=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil,tp)
		g:GetFirst():RemoveOverlayCard(tp,1,1,REASON_COST)
	end
end

--Target
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE_SUMMON,eg,#eg,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,#eg,0,0)
	-- SỬA LỖI: Thêm khai báo cho phần Special Summon
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

--GY summon filter
function s.spfilter(c,e,tp)
	return c:IsAttribute(ATTRIBUTE_DARK)
	and c:IsRace(RACE_WARRIOR)
	and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--Operation
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateSummon(eg) then
		Duel.Destroy(eg,REASON_EFFECT)
		Duel.BreakEffect()
		
		-- LƯU Ý LOGIC: 
		-- Nếu bạn MUỐN hiệu ứng Special Summon luôn xảy ra miễn là thỏa điều kiện dưới GY,
		-- hãy XÓA dòng kiểm tra s.synfilter bên dưới đi. 
		-- Hiện tại code vẫn đang bắt buộc phải có Synchro Level 13 trên sân thì mới Special Summon.
		if Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
		and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
			if #g>0 then
				Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
			end
		end
	end
end