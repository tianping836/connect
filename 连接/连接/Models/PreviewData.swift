import Foundation
import SwiftData

/// 用于 SwiftUI Preview 和开发阶段测试的预设数据
enum PreviewData {

    @MainActor
    static func create(modelContext: ModelContext) {
        // MARK: - 机构

        let court1 = Organization(name: "北京市朝阳区人民法院", type: .court, address: "北京市朝阳区朝阳公园南路甲2号")
        let court2 = Organization(name: "北京市海淀区人民法院", type: .court, address: "北京市海淀区丹棱街12号")
        let court3 = Organization(name: "北京市第三中级人民法院", type: .court, address: "北京市朝阳区广顺北大街32号")
        let proc1 = Organization(name: "北京市朝阳区人民检察院", type: .procuratorate, address: "北京市朝阳区六里屯西里7号")
        let proc2 = Organization(name: "北京市人民检察院第三分院", type: .procuratorate, address: "北京市朝阳区东三环南路98号")
        let ps1 = Organization(name: "北京市公安局朝阳分局", type: .publicSecurity, address: "北京市朝阳区工体南路甲1号")
        let tax = Organization(name: "国家税务总局北京市税务局稽查局", type: .taxBureau, address: "北京市西城区车公庄大街10号")
        let firm1 = Organization(name: "明德律师事务所", type: .lawFirm, address: "北京市朝阳区建国路88号")
        let orgs = [court1, court2, court3, proc1, proc2, ps1, tax, firm1]
        orgs.forEach { modelContext.insert($0) }

        // MARK: - 联系人（核心）

        // 法官
        let wangCY = Contact(name: "王朝阳", phone: "13801001234", wechat: "wcy_judge", roleTags: [.judge], organization: court1, rolesInOrg: [.judge], importance: 5, relationshipStage: .trusted)
        let liXM = Contact(name: "李雪梅", phone: "13801001235", wechat: "lixuemei_law", roleTags: [.judge], organization: court2, rolesInOrg: [.judge], importance: 4, relationshipStage: .familiar)
        let zhaoYG = Contact(name: "赵永刚", phone: "13801001236", roleTags: [.judge], organization: court3, rolesInOrg: [.judge], importance: 4, relationshipStage: .familiar)
        let xuZG = Contact(name: "许志刚", phone: "13801001248", roleTags: [.judge], organization: court1, rolesInOrg: [.judge], referrer: wangCY, importance: 3, relationshipStage: .newAcquaintance)

        // 书记员
        let chenXF = Contact(name: "陈小芳", phone: "13801001237", roleTags: [.clerk], organization: court1, rolesInOrg: [.clerk], importance: 3, relationshipStage: .familiar)
        let zhangLH = Contact(name: "张丽华", phone: "13801001239", roleTags: [.clerk], organization: court3, rolesInOrg: [.clerk], importance: 2, relationshipStage: .newAcquaintance)

        // 法官助理
        let liuMH = Contact(name: "刘明辉", phone: "13801001238", wechat: "lmh_assist", roleTags: [.judgeAssistant], organization: court2, rolesInOrg: [.judgeAssistant], importance: 3, relationshipStage: .familiar)

        // 检察官
        let sunZY = Contact(name: "孙志远", phone: "13801001241", wechat: "sunzy_proc", roleTags: [.prosecutor], organization: proc1, rolesInOrg: [.prosecutor], importance: 4, relationshipStage: .familiar)
        let wuXY = Contact(name: "吴晓燕", phone: "13801001242", wechat: "wuxy_jc", roleTags: [.prosecutor], organization: proc2, rolesInOrg: [.prosecutor], importance: 4, relationshipStage: .familiar)
        let zhengWT = Contact(name: "郑文涛", phone: "13801001243", roleTags: [.prosecutorAssistant], organization: proc1, rolesInOrg: [.prosecutorAssistant], importance: 2, relationshipStage: .newAcquaintance)

        // 公安
        let huangZQ = Contact(name: "黄志强", phone: "13801001244", roleTags: [.police], organization: ps1, importance: 3, relationshipStage: .familiar)

        // 稽查局
        let heWM = Contact(name: "何伟民", phone: "13801001246", roleTags: [.inspectionUnit], organization: tax, rolesInOrg: [.inspectionUnit], importance: 2, relationshipStage: .newAcquaintance)
        let linXF = Contact(name: "林晓峰", phone: "13801001247", roleTags: [.caseReviewUnit], organization: tax, rolesInOrg: [.caseReviewUnit], importance: 2, relationshipStage: .newAcquaintance)

        // 律师
        let fangWB = Contact(name: "方文博", phone: "13901008801", wechat: "fangwb_law", roleTags: [.lawyer], organization: firm1, rolesInOrg: [.lawyer], importance: 5, relationshipStage: .trusted, skillTags: ["商事诉讼", "并购重组"])
        let wangLN = Contact(name: "王丽娜", phone: "13901008802", wechat: "wanglina_legal", roleTags: [.lawyer], organization: firm1, rolesInOrg: [.lawyer], importance: 4, relationshipStage: .trusted, skillTags: ["刑事辩护"])

        // 当事人
        let chenGD = Contact(name: "陈国栋", phone: "13601005001", wechat: "chenguodong", roleTags: [.party], importance: 5, relationshipStage: .trusted, preferences: "喜欢喝铁观音", notes: "企业主，经营多年")
        let qianDJ = Contact(name: "钱大军", phone: "13601005002", wechat: "qiandajun", roleTags: [.party], referrer: chenGD, importance: 4, relationshipStage: .familiar, notes: "陈国栋老乡")
        let yangZW = Contact(name: "杨志伟", phone: "13601005004", wechat: "yangzw", roleTags: [.party], referrer: fangWB, importance: 4, relationshipStage: .trusted, notes: "建筑公司老板")
        let panXM = Contact(name: "潘晓明", phone: "13601005005", roleTags: [.party], referrer: fangWB, importance: 3, relationshipStage: .familiar, notes: "杨志伟的合作伙伴")
        let guoXL = Contact(name: "郭秀兰", phone: "13601005008", wechat: "guoxiulan", roleTags: [.party], importance: 3, relationshipStage: .familiar)
        let qinZM = Contact(name: "秦志明", phone: "13601005007", roleTags: [.party], referrer: yangZW, importance: 3, relationshipStage: .familiar, notes: "杨志伟生意伙伴")
        let jiangWD = Contact(name: "蒋卫东", phone: "13601005009", roleTags: [.party], referrer: panXM, importance: 3, relationshipStage: .newAcquaintance)
        let tangJH = Contact(name: "唐建华", phone: "13601005006", wechat: "tangjianhua", roleTags: [.other], referrer: chenGD, importance: 4, relationshipStage: .trusted, skillTags: ["审计", "税务"], notes: "会计师事务所合伙人")
        let mengXL = Contact(name: "孟祥龙", phone: "13601005012", wechat: "mengxl", roleTags: [.party], referrer: chenGD, importance: 3, relationshipStage: .familiar, notes: "房地产开发纠纷")

        // 证人
        let xieMQ = Contact(name: "谢美琴", phone: "13601005010", roleTags: [.witness], referrer: qianDJ, importance: 2, relationshipStage: .newAcquaintance, notes: "钱大军公司前员工")

        let contacts: [Contact] = [
            wangCY, liXM, zhaoYG, xuZG, chenXF, zhangLH, liuMH,
            sunZY, wuXY, zhengWT,
            huangZQ,
            heWM, linXF,
            fangWB, wangLN,
            chenGD, qianDJ, yangZW, panXM, guoXL, qinZM, jiangWD, tangJH, mengXL,
            xieMQ
        ]
        contacts.forEach { modelContext.insert($0) }

        // MARK: - 案件

        let case1Participants = [
            CaseParticipant(contact: yangZW, role: .client),
            CaseParticipant(contact: panXM, role: .opposingParty),
            CaseParticipant(contact: wangCY, role: .presidingJudge, roleDetail: "审判长"),
            CaseParticipant(contact: chenXF, role: .courtClerk),
        ]
        let case1Events = [
            KeyEvent(eventType: .filing, date: date(2025, 3, 15), title: "立案", detail: "北京市朝阳区人民法院受理"),
            KeyEvent(eventType: .evidenceSubmission, date: date(2025, 4, 10), title: "提交证据清单"),
            KeyEvent(eventType: .courtHearing, date: date(2025, 7, 15), title: "第四次开庭"),
        ]
        let case1 = CaseRecord(
            caseName: "建设工程施工合同纠纷",
            caseType: .civil,
            courtCaseNumber: "(2025)京0105民初15678号",
            internalCaseNumber: "MJ-2025-001",
            claimAmount: 5_000_000,
            caseStage: .inTrial,
            filingDate: date(2025, 3, 15),
            acceptedOrganization: court1,
            responsibleLawyer: fangWB,
            participants: case1Participants,
            keyEvents: case1Events
        )

        let case2Participants = [
            CaseParticipant(contact: chenGD, role: .client),
            CaseParticipant(contact: qinZM, role: .opposingParty),
            CaseParticipant(contact: liXM, role: .presidingJudge),
            CaseParticipant(contact: liuMH, role: .courtClerk, roleDetail: "法官助理协助"),
        ]
        let case2 = CaseRecord(
            caseName: "民间借贷纠纷",
            caseType: .civil,
            courtCaseNumber: "(2025)京0108民初20345号",
            internalCaseNumber: "MJ-2025-002",
            claimAmount: 800_000,
            caseStage: .inTrial,
            filingDate: date(2025, 4, 2),
            acceptedOrganization: court2,
            participants: case2Participants,
            keyEvents: [
                KeyEvent(eventType: .filing, date: date(2025, 4, 2), title: "立案"),
                KeyEvent(eventType: .courtHearing, date: date(2025, 8, 20), title: "首次开庭"),
            ]
        )

        let case3Participants = [
            CaseParticipant(contact: qinZM, role: .client),
            CaseParticipant(contact: yangZW, role: .opposingParty),
        ]
        let case3 = CaseRecord(
            caseName: "股权转让纠纷",
            caseType: .civil,
            courtCaseNumber: "(2025)京0105民初28901号",
            internalCaseNumber: "MJ-2025-003",
            caseResult: "双方达成调解，以股权回购方式结案",
            caseStage: .mediated,
            filingDate: date(2025, 5, 10),
            participants: case3Participants,
            keyEvents: [
                KeyEvent(eventType: .filing, date: date(2025, 5, 10), title: "立案"),
                KeyEvent(eventType: .mediation, date: date(2025, 7, 28), title: "调解成功"),
            ]
        )

        let case4 = CaseRecord(
            caseName: "离婚纠纷",
            caseType: .civil,
            internalCaseNumber: "MJ-2025-004",
            caseStage: .inTrial,
            filingDate: date(2025, 6, 1),
            acceptedOrganization: court2,
            participants: [CaseParticipant(contact: guoXL, role: .client)]
        )

        let case5 = CaseRecord(
            caseName: "买卖合同纠纷",
            caseType: .civil,
            courtCaseNumber: "(2025)京03民终4567号",
            internalCaseNumber: "MJ-2024-015",
            caseResult: "维持原判，我方胜诉",
            caseStage: .closed,
            filingDate: date(2024, 11, 20),
            closingDate: date(2025, 2, 28),
            acceptedOrganization: court3,
            participants: [CaseParticipant(contact: jiangWD, role: .client)],
            keyEvents: [
                KeyEvent(eventType: .filing, date: date(2024, 11, 20), title: "一审立案"),
                KeyEvent(eventType: .sentencing, date: date(2025, 1, 15), title: "一审判决"),
                KeyEvent(eventType: .closing, date: date(2025, 2, 28), title: "二审维持原判"),
            ]
        )

        let case6 = CaseRecord(
            caseName: "诈骗案",
            caseType: .criminal,
            courtCaseNumber: "(2025)京0105刑初8901号",
            internalCaseNumber: "MJ-2025-005",
            caseStage: .inTrial,
            filingDate: date(2025, 1, 8),
            acceptedOrganization: proc1,
            participants: [
                CaseParticipant(contact: guoXL, role: .client),
                CaseParticipant(contact: sunZY, role: .prosecutorInCharge),
            ],
            keyEvents: [
                KeyEvent(eventType: .filing, date: date(2025, 1, 8), title: "公安立案"),
                KeyEvent(eventType: .courtHearing, date: date(2025, 9, 5), title: "首次开庭"),
            ]
        )

        let case7 = CaseRecord(
            caseName: "公司股权架构设计",
            caseType: .nonLitigation,
            internalCaseNumber: "MJ-2025-010",
            caseStage: .retained,
            filingDate: date(2025, 7, 10),
            participants: [
                CaseParticipant(contact: panXM, role: .client),
                CaseParticipant(contact: fangWB, role: .coCounsel),
            ],
            notes: "新设合资公司，方文博协同承办"
        )

        let case8 = CaseRecord(
            caseName: "刑事合规专项",
            caseType: .nonLitigation,
            internalCaseNumber: "MJ-2025-011",
            caseStage: .retained,
            filingDate: date(2025, 8, 1),
            participants: [CaseParticipant(contact: tangJH, role: .client)]
        )

        let case9 = CaseRecord(
            caseName: "税务行政处罚复议",
            caseType: .administrative,
            internalCaseNumber: "MJ-2025-008",
            caseStage: .consulting,
            filingDate: date(2025, 6, 15),
            acceptedOrganization: tax,
            participants: [
                CaseParticipant(contact: chenGD, role: .client),
                CaseParticipant(contact: heWM, role: .other, roleDetail: "稽查经办人"),
            ],
            notes: "企业所得税罚款争议"
        )

        [case1, case2, case3, case4, case5, case6, case7, case8, case9].forEach {
            modelContext.insert($0)
        }

        // MARK: - 互动记录示例

        let interactions: [Interaction] = [
            Interaction(contact: wangCY, type: .visit, date: date(2025, 7, 10), detail: "法院谈案情进展", nextFollowUpDate: date(2025, 7, 20)),
            Interaction(contact: chenGD, type: .meal, date: date(2025, 6, 15), detail: "铁观音会所午餐，介绍唐建华认识", amount: 680),
            Interaction(contact: fangWB, type: .wechat, date: date(2025, 7, 1), detail: "转介绍杨志伟案件"),
            Interaction(contact: qianDJ, type: .giftReceived, date: date(2025, 3, 8), detail: "春节送礼：茅台2瓶", amount: 3200),
        ]
        interactions.forEach { modelContext.insert($0) }

        // MARK: - 人脉关系（交叉连线）

        let relations: [ContactRelation] = [
            // 方文博 和 王丽娜 是同事（同律所）
            ContactRelation(source: fangWB, target: wangLN, type: .colleague, note: "明德律师事务所合伙人"),
            // 方文博 和 李雪梅 是同学
            ContactRelation(source: fangWB, target: liXM, type: .classmate, note: "北大法学院同学"),
            // 陈国栋 和 钱大军 是朋友
            ContactRelation(source: chenGD, target: qianDJ, type: .friend, note: "多年好友"),
            // 王朝阳 和 赵永刚 是同事（不同法院但相识）
            ContactRelation(source: wangCY, target: zhaoYG, type: .acquaintance, note: "行业会议认识"),
            // 杨志伟 和 唐建华 是业务合作关系
            ContactRelation(source: yangZW, target: tangJH, type: .business, note: "审计项目合作"),
        ]
        relations.forEach { modelContext.insert($0) }

        try? modelContext.save()
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
