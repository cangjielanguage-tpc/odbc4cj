// EXEC: cjc %import-path %L %l %f
// EXEC: ./main

import std.database.sql.*
import std.io.*
import std.time.*
import std.regex.*
import odbc4cj.*
import std.unittest.*
import std.unittest.testmacro.*

main(): Int64 {
    let odbcTest: OdbcTest = OdbcTest()

    odbcTest.test001()
    odbcTest.test002()
    odbcTest.test003()
    odbcTest.test004()
    odbcTest.test005()

    return 0
}

@Test
public class OdbcTest {
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        @Assert('', driver.name)
        @Assert("", driver.version)
        @Assert(false, driver.preferredPooling)
        try{
            var database = driver.open("DATABASE=mysql;UID=root")
            @Assert(1, 0)
        }catch(e:SqlException){
            @Assert("Url is error, errorCode: 0", e.message)
        }
        try{
            var database = driver.open("DATABASE;UID=root;PWD=123")
            @Assert(1, 0)
        }catch(e:SqlException){
            @Assert("Url is error, errorCode: 0", e.message)
        }
        try{
            var database = driver.open("DATABASE=mysql;UID=root;qwe=123")
            @Assert(1, 0)
        }catch(e:SqlException){
            @Assert("Url is error, errorCode: 0", e.message)
        }
    }

    @TestCase
    public func test002(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        database.setOption("1","1")
        // setOption(Int32, Int64) 是 OdbcDatasource 专有方法，连接池代理不可达，使用直连数据源
        var directDatabase = OdbcDatasource()
        directDatabase.setOption(Int32(1),1)
        database.close()
        database.isClosed()
    }

    @TestCase
    public func test003(): Unit {
        // objId/getInfo 是 OdbcConnection 专有方法，连接池代理不可达，使用直连数据源
        var database = OdbcDatasource()
        database.setOption(SqlOption.URL, "DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        @Assert(true, conn.objId >= 0)
        conn.getMetaData()
        try{
            conn.getInfo(0,1)
            @Assert(1, 0)
        }catch(e:SqlException){
            @Assert("len is not 2, 4 or >=8., errorCode: 0", e.message)
        }
    }

    @TestCase
    public func test004(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var prepareStatement = conn.prepareStatement("drop table if exists test_llt")
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test_llt(data char(20) NOT NULL, datanull char(20))")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        @Assert(0, rowCount.lastInsertId)
        prepareStatement = conn.prepareStatement("insert into test_llt values(?,?)")
        prepareStatement.set<String>(0, "abc")
        prepareStatement.set<Option<String>>(1, Option<String>.None)
        // prepareStatement.setNull(1)
        rowCount = prepareStatement.update()
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test_llt")
        var queryResult = prepareStatement.query()
        let a = queryResult.next()
        @Assert(true, a)
        @Assert("SqlString", queryResult.columnInfos[0].typeName)
        @Assert("data", queryResult.columnInfos[0].name)
        @Assert(0, queryResult.columnInfos[0].length)
        @Assert(0, queryResult.columnInfos[0].scale)
        @Assert(false, queryResult.columnInfos[0].nullable)
        @Assert("abc", queryResult.get<String>(0))
        @Assert("SqlString", queryResult.columnInfos[1].typeName)
        @Assert("datanull", queryResult.columnInfos[1].name)
        @Assert(0, queryResult.columnInfos[1].length)
        @Assert(0, queryResult.columnInfos[1].scale)
        @Assert(true, queryResult.columnInfos[1].nullable)
        @Assert(None, queryResult.getOrNull<String>(1))
        queryResult.close()
    }

    @TestCase
    public func test005(): Unit {
        var date = DateTime.of(
            year: 2009,
            month: 11,
            dayOfMonth: 21,
            hour: 13,
            minute: 15,
            second: 35,
            nanosecond: 0,
        )
        let sqlTimestampWithoutTz = SqlTimestampWithoutTz(date)
        let sqlNullableTimestampWithoutTz  = SqlNullableTimestampWithoutTz (date)
        @Assert("SqlTimestampWithoutTz", sqlTimestampWithoutTz.name)
        @Assert("SqlNullableTimestampWithoutTz", sqlNullableTimestampWithoutTz.name)
        let odbcTypeDate = OdbcTypeDate(date)
        odbcTypeDate.value = date
        @Assert("DATE", odbcTypeDate.name)
        let odbcTypeTime = OdbcTypeTime(date)
        odbcTypeTime.value = date
        @Assert("TIME", odbcTypeTime.name)

        let odbcTypeEnum1 = OdbcTypeEnum.SqlString
        let odbcTypeEnum2 = OdbcTypeEnum.SqlArrayByte
        let odbcTypeEnum3 = OdbcTypeEnum.SqlInputStream
        let odbcTypeEnum4 = OdbcTypeEnum.SqlClob
        let odbcTypeEnum5 = OdbcTypeEnum.SqlBool
        let odbcTypeEnum6 = OdbcTypeEnum.SqlInt8
        let odbcTypeEnum7 = OdbcTypeEnum.SqlInt16
        let odbcTypeEnum8 = OdbcTypeEnum.SqlInt32
        let odbcTypeEnum9 = OdbcTypeEnum.SqlInt64
        let odbcTypeEnum10 = OdbcTypeEnum.SqlFloat32
        let odbcTypeEnum11 = OdbcTypeEnum.SqlFloat64
        let odbcTypeEnum12 = OdbcTypeEnum.SqlDateTime
        let odbcTypeEnum13 = OdbcTypeEnum.SqlOdbcTypeDate
        let odbcTypeEnum14 = OdbcTypeEnum.SqlOdbcTypeTime
        let odbcTypeEnum15 = OdbcTypeEnum.SqlOdbcTypeTimeTimestamp
        let odbcTypeEnum16 = OdbcTypeEnum.SqlDecimal
        let odbcTypeEnum17 = OdbcTypeEnum.SqlNull
        let odbcTypeEnum18 = OdbcTypeEnum.SqlBigInt
        let odbcTypeEnum19 = OdbcTypeEnum.SqlOther

        @Assert(true, odbcTypeEnum1 == odbcTypeEnum1)
        @Assert(true, odbcTypeEnum2 == odbcTypeEnum2)
        @Assert(true, odbcTypeEnum3 == odbcTypeEnum3)
        @Assert(true, odbcTypeEnum4 == odbcTypeEnum4)
        @Assert(true, odbcTypeEnum5 == odbcTypeEnum5)
        @Assert(true, odbcTypeEnum6 == odbcTypeEnum6)
        @Assert(true, odbcTypeEnum7 == odbcTypeEnum7)
        @Assert(true, odbcTypeEnum8 == odbcTypeEnum8)
        @Assert(true, odbcTypeEnum9 == odbcTypeEnum9)
        @Assert(true, odbcTypeEnum10 == odbcTypeEnum10)
        @Assert(true, odbcTypeEnum11 == odbcTypeEnum11)
        @Assert(true, odbcTypeEnum12 == odbcTypeEnum12)
        @Assert(true, odbcTypeEnum13 == odbcTypeEnum13)
        @Assert(true, odbcTypeEnum14 == odbcTypeEnum14)
        @Assert(true, odbcTypeEnum15 == odbcTypeEnum15)
        @Assert(true, odbcTypeEnum16 == odbcTypeEnum16)
        @Assert(true, odbcTypeEnum17 == odbcTypeEnum17)
        @Assert(true, odbcTypeEnum18 == odbcTypeEnum18)
        @Assert(true, odbcTypeEnum19 == odbcTypeEnum19)
        @Assert(false, odbcTypeEnum19 == odbcTypeEnum1)
        @Assert(false, odbcTypeEnum1 != odbcTypeEnum1)
        @Assert(true, odbcTypeEnum19 != odbcTypeEnum1)

        @Assert("SqlString", odbcTypeEnum1.toString())
        @Assert("SqlArrayByte", odbcTypeEnum2.toString())
        @Assert("SqlInputStream", odbcTypeEnum3.toString())
        @Assert("SqlClob", odbcTypeEnum4.toString())
        @Assert("SqlBool", odbcTypeEnum5.toString())
        @Assert("SqlInt8", odbcTypeEnum6.toString())
        @Assert("SqlInt16", odbcTypeEnum7.toString())
        @Assert("SqlInt32", odbcTypeEnum8.toString())
        @Assert("SqlInt64", odbcTypeEnum9.toString())
        @Assert("SqlFloat32", odbcTypeEnum10.toString())
        @Assert("SqlFloat64", odbcTypeEnum11.toString())
        @Assert("SqlDateTime", odbcTypeEnum12.toString())
        @Assert("SqlOdbcTypeDate", odbcTypeEnum13.toString())
        @Assert("SqlOdbcTypeTime", odbcTypeEnum14.toString())
        @Assert("SqlOdbcTypeTimeTimestamp", odbcTypeEnum15.toString())
        @Assert("SqlDecimal", odbcTypeEnum16.toString())
        @Assert("SqlNull", odbcTypeEnum17.toString())
        @Assert("SqlBigInt", odbcTypeEnum18.toString())
        @Assert("SqlOther", odbcTypeEnum19.toString())

        @Assert(OdbcTypeEnum.fromToString("SqlString"), odbcTypeEnum1)
        @Assert(OdbcTypeEnum.fromToString("SqlArrayByte"), odbcTypeEnum2)
        @Assert(OdbcTypeEnum.fromToString("SqlInputStream"), odbcTypeEnum3)
        @Assert(OdbcTypeEnum.fromToString("SqlClob"), odbcTypeEnum4)
        @Assert(OdbcTypeEnum.fromToString("SqlBool"), odbcTypeEnum5)
        @Assert(OdbcTypeEnum.fromToString("SqlInt8"), odbcTypeEnum6)
        @Assert(OdbcTypeEnum.fromToString("SqlInt16"), odbcTypeEnum7)
        @Assert(OdbcTypeEnum.fromToString("SqlInt32"), odbcTypeEnum8)
        @Assert(OdbcTypeEnum.fromToString("SqlInt64"), odbcTypeEnum9)
        @Assert(OdbcTypeEnum.fromToString("SqlFloat32"), odbcTypeEnum10)
        @Assert(OdbcTypeEnum.fromToString("SqlFloat64"), odbcTypeEnum11)
        @Assert(OdbcTypeEnum.fromToString("SqlDateTime"), odbcTypeEnum12)
        @Assert(OdbcTypeEnum.fromToString("SqlOdbcTypeDate"), odbcTypeEnum13)
        @Assert(OdbcTypeEnum.fromToString("SqlOdbcTypeTime"), odbcTypeEnum14)
        @Assert(OdbcTypeEnum.fromToString("SqlOdbcTypeTimeTimestamp"), odbcTypeEnum15)
        @Assert(OdbcTypeEnum.fromToString("SqlDecimal"), odbcTypeEnum16)
        @Assert(OdbcTypeEnum.fromToString("SqlNull"), odbcTypeEnum17)
        @Assert(OdbcTypeEnum.fromToString("SqlBigInt"), odbcTypeEnum18)
        @Assert(OdbcTypeEnum.fromToString("SqlOther"), odbcTypeEnum19)
        try{
            OdbcTypeEnum.fromToString("")
            @Assert(1, 0)
        }catch(e:SqlException){
            @Assert("Unknown odbc typeEnum:, errorCode: 0", e.message)
        }
    }

    @TestCase
    public func test006(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var prepareStatement = conn.prepareStatement("drop table if exists test_llt")
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test_llt(data char(20) NOT NULL, datanull char(20))")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test_llt")
        var queryResult = prepareStatement.query()
        let a = queryResult.next()
        @Assert(false, a)
    }
}