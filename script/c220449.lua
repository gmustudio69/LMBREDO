-- The Planet
local s, id, o = GetID()

-- Hàm khởi tạo hiệu ứng của lá bài
function s.initial_effect(c)
    -- Hiệu ứng 1: Tìm kiếm và đưa lá bài có ID 220448 vào tay
    local e1 = Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_TOHAND + CATEGORY_SEARCH + CATEGORY_SPECIAL_SUMMON) -- Thể loại: Tìm kiếm, đưa vào tay, Triệu hồi Đặc biệt
    e1:SetType(EFFECT_TYPE_ACTIVATE) -- Loại hiệu ứng: Kích hoạt
    e1:SetCode(EVENT_FREE_CHAIN) -- Mã sự kiện: Chuỗi tự do
    e1:SetCountLimit(1, id + EFFECT_COUNT_CODE_OATH) -- Giới hạn số lần kích hoạt: 1 lần mỗi trận đấu
    e1:SetOperation(s.activate) -- Đặt hàm s.activate làm hành động
    c:RegisterEffect(e1) -- Đăng ký hiệu ứng e1 cho lá bài c

    -- Hiệu ứng 2: Triệu hồi Xyz Rank 12
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1)) -- Mô tả hiệu ứng
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON) -- Thể loại: Triệu hồi Đặc biệt
    e2:SetType(EFFECT_TYPE_IGNITION) -- Loại hiệu ứng: Kích hoạt (ignition)
    e2:SetRange(LOCATION_SZONE) -- Phạm vi: Trên sân
    e2:SetCountLimit(1,id+o*2) -- Giới hạn số lần kích hoạt: 1 lần mỗi lượt
    e2:SetTarget(s.Xyztg)
	e2:SetOperation(s.Xyzop)
    c:RegisterEffect(e2) -- Đăng ký hiệu ứng e2 cho lá bài c
end

-- Hàm lọc lá bài có ID 220448 và có thể đưa vào tay
function s.thfilter(c)
    return c:IsCode(220448) and c:IsAbleToHand()
end

-- Hàm thực hiện hiệu ứng tìm kiếm và đưa lá bài vào tay
function s.activate(e, tp, eg, ep, ev, re, r, rp)
    local g = Duel.GetMatchingGroup(s.thfilter, tp, LOCATION_DECK, 0, nil) -- Lấy nhóm lá bài thỏa mãn điều kiện
    if g:GetCount() > 0 and Duel.SelectYesNo(tp, aux.Stringid(id, 0)) then -- Nếu có lá bài và người chơi muốn kích hoạt
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND) -- Hiển thị thông báo chọn lá bài
        local sg = g:Select(tp, 1, 1, nil) -- Chọn 1 lá bài
        Duel.SendtoHand(sg, nil, REASON_EFFECT) -- Đưa lá bài vào tay
        Duel.ConfirmCards(1 - tp, sg) -- Hiển thị lá bài cho đối thủ
    end
end

function s.filter1(c,e,tp)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsRank(12)
		and Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,c)
		and aux.MustMaterialCheck(c,tp,EFFECT_MUST_BE_XMATERIAL)
end
function s.filter2(c,e,tp,mc)
	return c:IsRank(12) and mc:IsCanBeXyzMaterial(c)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false) and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
end
function s.Xyztg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.filter1(chkc,e,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.filter1,tp,LOCATION_MZONE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.filter1,tp,LOCATION_MZONE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.Xyzop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not aux.MustMaterialCheck(tc,tp,EFFECT_MUST_BE_XMATERIAL) then return end
	if tc:IsFacedown() or not tc:IsRelateToEffect(e) or tc:IsControler(1-tp) or tc:IsImmuneToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.filter2,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc)
	local sc=g:GetFirst()
	if sc then
		local mg=tc:GetOverlayGroup()
		if mg:GetCount()~=0 then
			Duel.Overlay(sc,mg)
		end
		sc:SetMaterial(Group.FromCards(tc))
		Duel.Overlay(sc,Group.FromCards(tc))
		Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
		sc:CompleteProcedure()
	end
end